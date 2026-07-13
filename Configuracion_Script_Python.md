# Instrucciones para correr el script de las metas (sync_metas_excel.py)

Este script agarra el Excel de metas y lo mete al Data Warehouse. Antes de correrlo, ya debe estar creada la base fuente, el DW, y haber corrido el ETL completo al menos una vez (`CALL sp_ejecutar_etl();`), porque el script necesita que DIM_PRODUCTO ya tenga datos cargados.

## 1. Entrar a la carpeta

El script vive en la carpeta `Integracion Excel Metas`, junto con el Excel y el `requirements.txt`. Hay que abrir la terminal ahí:

```
cd "Integracion Excel Metas"
```

## 2. Instalar lo que necesita

```
pip install -r requirements.txt
```

Con eso se instalan pandas (para leer el Excel), openpyxl (que es lo que pandas usa por debajo para abrir archivos .xlsx) y psycopg2-binary (para hablar con PostgreSQL).

## 3. Decirle a qué base conectarse

Esta es la parte que suele cambiar según la máquina donde se corra. Se le pasa por parámetros al ejecutar el comando:

```
python sync_metas_excel.py --excel Metas_Seguros.xlsx --host localhost --port 5432 --dbname seguros --user postgres --password TU_CONTRASEÑA
```

Hay que cambiar `seguros`, `postgres` y la contraseña por lo que tenga configurado la instalación de PostgreSQL en cada caso. Si no se pasa ningún parámetro, el script intenta conectarse con esos mismos valores por defecto (localhost, puerto 5432, base "seguros", usuario "postgres", sin contraseña).

También se puede dejar la conexión puesta como variables de entorno para no escribirla cada vez:

```
set PGHOST=localhost
set PGDATABASE=seguros
set PGUSER=postgres
set PGPASSWORD=TU_CONTRASEÑA
python sync_metas_excel.py --excel Metas_Seguros.xlsx
```

(en Mac/Linux es `export` en vez de `set`)

## 4. La ruta del Excel

Si el script se corre desde dentro de la misma carpeta donde está `Metas_Seguros.xlsx`, con poner el nombre del archivo basta, como arriba. Si se corre desde otro lado, hay que poner la ruta completa:

```
python sync_metas_excel.py --excel "C:\donde\sea\Metas_Seguros.xlsx" --dbname seguros --user postgres
```

## 5. Qué debería verse si sale bien

Algo así en la consola:

```
Excel valido: 50 metas, anios [2022, 2023, 2024, 2025, 2026].
Staging: 50 filas cargadas en seguro_g30871276.stg_metas_excel.
CALL seguro_dw_g30871276.sp_cargar_fact_metas() ...
FACT_METAS tras la corrida: 50 filas | suma monto_meta_ingreso = ...
COMMIT. Sincronizacion completada.
```

Si algo falla, sale un `ERROR:` explicando qué pasó, y no queda nada a medias — hace rollback solo, la base queda como estaba antes de correr el script.

El script puede correrse las veces que se quiera, no duplica nada: si se vuelve a correr con el mismo Excel, los números de FACT_METAS quedan igual. Si se cambia un monto en el Excel y se guarda, la próxima corrida solo actualiza esa fila.
