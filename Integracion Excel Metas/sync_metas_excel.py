#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
sync_metas_excel.py - Sincroniza Metas_Seguros.xlsx con el Data Warehouse.
Proyecto BI Seguros Alta Vista (Panza / Mejia / De Sousa).

Flujo (E-T-L conservado: Python solo EXTRAE; la carga al hecho sigue siendo
el procedimiento PL/pgSQL de la Fase II):

    Excel (hoja METAS)
        -> validacion en Python (columnas, tipos, duplicados, nulos)
        -> TRUNCATE + INSERT en seguro_g30871276.stg_metas_excel   [1 transaccion]
        -> CALL seguro_dw_g30871276.sp_cargar_fact_metas()         [misma transaccion]
        -> COMMIT (o ROLLBACK total si algo falla: el DW nunca queda a medias)

Uso:
    python sync_metas_excel.py                          # una corrida
    python sync_metas_excel.py --watch                  # vigila el archivo y
                                                        # sincroniza solo al detectar cambios
    python sync_metas_excel.py --full-etl               # corre el ETL completo
    python sync_metas_excel.py --excel /ruta/Metas.xlsx --host 10.0.0.5 --port 5432

Conexion: parametros CLI > variables de entorno PGHOST/PGPORT/PGDATABASE/
PGUSER/PGPASSWORD > defaults (localhost:5432/seguros/postgres).

Dependencias:  pip install pandas openpyxl psycopg2-binary
"""

import argparse
import hashlib
import os
import sys
import time
from datetime import datetime

import pandas as pd
import psycopg2
from psycopg2.extras import execute_values

# ---------------------------------------------------------------------------
STAGING_TABLE = "seguro_g30871276.stg_metas_excel"
PROC_METAS    = "seguro_dw_g30871276.sp_cargar_fact_metas()"
PROC_FULL_ETL = "seguro_dw_g30871276.sp_ejecutar_etl()"
SHEET         = "METAS"

REQUIRED_COLS = ["anio", "cod_producto", "monto_meta_ingreso",
                 "meta_renovacion", "meta_asegurados"]


def log(msg: str) -> None:
    print(f"[{datetime.now():%Y-%m-%d %H:%M:%S}] {msg}", flush=True)


# ---------------------------------------------------------------------------
# 1) EXTRACCION + VALIDACION del Excel
# ---------------------------------------------------------------------------
def leer_excel(path: str) -> pd.DataFrame:
    if not os.path.isfile(path):
        raise FileNotFoundError(f"No existe el archivo: {path}")

    try:
        df = pd.read_excel(path, sheet_name=SHEET, engine="openpyxl")
    except ValueError as e:
        raise ValueError(f"El archivo no tiene la hoja '{SHEET}': {e}") from e

    df.columns = [str(c).strip().lower() for c in df.columns]

    faltantes = [c for c in REQUIRED_COLS if c not in df.columns]
    if faltantes:
        raise ValueError(f"Faltan columnas obligatorias en la hoja {SHEET}: {faltantes}")

    # Ignorar filas totalmente vacias (colas de Excel)
    df = df.dropna(how="all").copy()
    if df.empty:
        raise ValueError("La hoja METAS no tiene filas de datos. "
                         "Por seguridad no se sincroniza un Excel vacio.")

    # Nulos en columnas obligatorias
    con_nulos = df[REQUIRED_COLS].isna().any(axis=1)
    if con_nulos.any():
        filas = (df.index[con_nulos] + 2).tolist()  # +2: header + base 1 de Excel
        raise ValueError(f"Celdas vacias en columnas obligatorias, filas Excel: {filas}")

    # Tipos
    try:
        df["anio"] = df["anio"].astype(int)
        df["cod_producto"] = df["cod_producto"].astype(int)
        df["meta_renovacion"] = df["meta_renovacion"].astype(int)
        df["meta_asegurados"] = df["meta_asegurados"].astype(int)
        df["monto_meta_ingreso"] = df["monto_meta_ingreso"].astype(float)
    except (ValueError, TypeError) as e:
        raise ValueError(f"Tipo de dato invalido en la hoja METAS: {e}") from e

    # Rangos razonables
    fuera = df[(df["anio"] < 2000) | (df["anio"] > 2100)]
    if not fuera.empty:
        raise ValueError(f"Valores de 'anio' fuera de rango 2000-2100: {sorted(fuera['anio'].unique())}")
    neg = df[(df["monto_meta_ingreso"] < 0) | (df["meta_renovacion"] < 0) | (df["meta_asegurados"] < 0)]
    if not neg.empty:
        raise ValueError(f"Metas negativas en filas Excel: {(neg.index + 2).tolist()}")

    # Clave de negocio unica: (anio, cod_producto)
    dup = df[df.duplicated(subset=["anio", "cod_producto"], keep=False)]
    if not dup.empty:
        pares = dup[["anio", "cod_producto"]].drop_duplicates().values.tolist()
        raise ValueError(f"Pares (anio, cod_producto) duplicados en el Excel: {pares}. "
                         "Debe haber UNA fila por producto por anio.")

    return df[REQUIRED_COLS]


# ---------------------------------------------------------------------------
# 2) CARGA a staging + CALL al procedimiento, todo en UNA transaccion
# ---------------------------------------------------------------------------
def sincronizar(df: pd.DataFrame, conn_params: dict, full_etl: bool) -> None:
    filas = [
        (int(r.anio), int(r.cod_producto), float(r.monto_meta_ingreso),
         int(r.meta_renovacion), int(r.meta_asegurados))
        for r in df.itertuples(index=False)
    ]

    conn = psycopg2.connect(**conn_params)
    try:
        conn.autocommit = False
        with conn.cursor() as cur:
            cur.execute(f"TRUNCATE {STAGING_TABLE};")
            execute_values(
                cur,
                f"""INSERT INTO {STAGING_TABLE}
                    (anio, cod_producto, monto_meta_ingreso,
                     meta_renovacion, meta_asegurados)
                    VALUES %s""",
                filas,
            )
            log(f"Staging: {len(filas)} filas cargadas en {STAGING_TABLE}.")

            proc = PROC_FULL_ETL if full_etl else PROC_METAS
            log(f"CALL {proc} ...")
            cur.execute(f"CALL {proc};")
            for n in conn.notices:                 # RAISE NOTICE del PL/pgSQL
                print("    " + n.strip(), flush=True)

            cur.execute("""
                SELECT COUNT(*), COALESCE(SUM(monto_meta_ingreso), 0)
                FROM seguro_dw_g30871276.fact_metas;""")
            n, total = cur.fetchone()
            log(f"FACT_METAS tras la corrida: {n} filas | suma monto_meta_ingreso = {total:,.2f}")

        conn.commit()
        log("COMMIT. Sincronizacion completada.")
    except Exception:
        conn.rollback()
        log("ROLLBACK. El DW quedo intacto.")
        raise
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# 3) Modo --watch: hash del contenido, no solo mtime (Excel a veces re-guarda
#    con la misma marca de tiempo o el mtime cambia sin cambios reales)
# ---------------------------------------------------------------------------
def hash_archivo(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for bloque in iter(lambda: f.read(65536), b""):
            h.update(bloque)
    return h.hexdigest()


def modo_watch(path: str, conn_params: dict, full_etl: bool, intervalo: int) -> None:
    log(f"Vigilando {path} cada {intervalo}s (Ctrl+C para salir).")
    ultimo = None
    while True:
        try:
            if os.path.isfile(path):
                actual = hash_archivo(path)
                if actual != ultimo:
                    if ultimo is not None:
                        log("Cambio detectado en el Excel.")
                    try:
                        df = leer_excel(path)
                        sincronizar(df, conn_params, full_etl)
                        ultimo = actual          # solo se marca si la corrida fue OK
                    except Exception as e:
                        log(f"ERROR (se reintentara al proximo cambio): {e}")
                        ultimo = actual          # no reintentar el mismo archivo roto en bucle
            else:
                log("El archivo no existe todavia; esperando...")
        except KeyboardInterrupt:
            log("Detenido por el usuario.")
            return
        except PermissionError:
            log("Archivo bloqueado (Excel abierto guardando); reintento en el proximo ciclo.")
        time.sleep(intervalo)


# ---------------------------------------------------------------------------
def main() -> int:
    p = argparse.ArgumentParser(description="Sincroniza Metas_Seguros.xlsx -> Data Warehouse")
    p.add_argument("--excel", default="Metas_Seguros.xlsx", help="Ruta del Excel (default: ./Metas_Seguros.xlsx)")
    p.add_argument("--host", default=os.getenv("PGHOST", "localhost"))
    p.add_argument("--port", default=os.getenv("PGPORT", "5432"))
    p.add_argument("--dbname", default=os.getenv("PGDATABASE", "seguros"))
    p.add_argument("--user", default=os.getenv("PGUSER", "postgres"))
    p.add_argument("--password", default=os.getenv("PGPASSWORD", ""))
    p.add_argument("--full-etl", action="store_true",
                   help="Correr sp_ejecutar_etl() completo en vez de solo sp_cargar_fact_metas()")
    p.add_argument("--watch", action="store_true", help="Vigilar el archivo y sincronizar al detectar cambios")
    p.add_argument("--interval", type=int, default=5, help="Segundos entre chequeos en modo --watch (default 5)")
    args = p.parse_args()

    conn_params = dict(host=args.host, port=args.port, dbname=args.dbname,
                       user=args.user, password=args.password)

    if args.watch:
        modo_watch(args.excel, conn_params, args.full_etl, args.interval)
        return 0

    try:
        df = leer_excel(args.excel)
        log(f"Excel valido: {len(df)} metas, anios {sorted(df['anio'].unique().tolist())}.")
        sincronizar(df, conn_params, args.full_etl)
        return 0
    except Exception as e:
        log(f"ERROR: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
