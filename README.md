# Proyecto BI — Seguros Alta Vista

Solución de Inteligencia de Negocios (UCAB, Marzo–Julio 2026).
Panza / Mejía / De Sousa — Prof. Concettina Di Vasta.

## Estructura del repositorio

```
BD Transaccional + Data Warehouse/
  SEGURO_G30871276.sql               BD transaccional (fuente) — PostgreSQL
  Inserts_SEGURO.sql                 Datos de prueba de la fuente
  SEGURO_DW_G30871276.sql            Data Warehouse (constelación: 4 hechos, 8 dimensiones)
  ETL_PLPGSQL_SEGUROS_G30871276.sql  ETL en PL/pgSQL: SCD1, smart key AAAAMMDD,
                                     carga incremental (upsert + synchronize)
  Defensa_EnVivo.sql                 Guion de la demo incremental para la defensa
Integracion Excel Metas/
  Metas_Seguros.xlsx                 Hoja de metas de la Gerencia de Estadística
                                     (fuente real de FACT_METAS)
  sync_metas_excel.py                Sincronizador Excel -> staging -> FACT_METAS
  requirements.txt                   Dependencias Python
```

## Orden de ejecución (desde cero)

```
1. SEGURO_G30871276.sql          -- crea el esquema fuente
2. Inserts_SEGURO.sql            -- datos de prueba (correr con search_path=seguro_g30871276)
3. SEGURO_DW_G30871276.sql       -- crea el DW
4. ETL_PLPGSQL_SEGUROS_G30871276.sql   -- crea procedimientos + staging de metas
5. CALL seguro_dw_g30871276.sp_ejecutar_etl();   -- carga dimensiones y hechos
                                                 -- (FACT_METAS se omite: staging aun vacio)
6. pip install -r "Integracion Excel Metas/requirements.txt"
7. python sync_metas_excel.py --excel Metas_Seguros.xlsx   -- carga las metas del Excel
```

Notas:
- El ETL completo (paso 5) debe correr ANTES del primer sync: FACT_METAS
  referencia DIM_PRODUCTO, y las dimensiones las carga el ETL. Despues de la
  primera carga, el sync puede correrse solo, cuantas veces se quiera.
- `sync_metas_excel.py --watch` deja el sincronizador vigilando el Excel y
  aplica los cambios (altas, modificaciones y bajas de metas) automáticamente.
- Conexión del script: parámetros CLI (`--host --port --dbname --user --password`)
  o variables de entorno estándar `PGHOST/PGPORT/PGDATABASE/PGUSER/PGPASSWORD`.

## Flujo de las metas (Excel -> DW)

```
Metas_Seguros.xlsx (hoja METAS)
   -> sync_metas_excel.py: valida (columnas, tipos, duplicados, nulos)
   -> TRUNCATE + INSERT en seguro_g30871276.stg_metas_excel   [1 transacción]
   -> CALL sp_cargar_fact_metas()  (upsert + synchronize)     [misma transacción]
   -> COMMIT  (ROLLBACK total ante cualquier error: el DW nunca queda a medias)
```
