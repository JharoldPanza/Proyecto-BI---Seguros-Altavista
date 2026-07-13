# Proyecto BI — Seguros Alta Vista

Solución de Inteligencia de Negocios para Seguros Alta Vista (UCAB, Marzo–Julio 2026).
Panza / Mejía / De Sousa — Prof. Concettina Di Vasta.

## Qué Se necesita antes de empezar

- PostgreSQL instalado y corriendo.
- Un cliente para ejecutar archivos `.sql` (psql, pgAdmin).
- Python 3.

## Cómo levantar el proyecto

Correr en este orden. Los primeros cinco pasos están dentro de la carpeta `BD Transaccional + Data Warehouse/`.

1. **`SEGURO_G30871276.sql`** — crea la base de datos transaccional.
2. **`Inserts_SEGURO.sql`** — carga los datos de prueba en esa base.
3. **`SEGURO_DW_G30871276.sql`** — crea el Data Warehouse.
4. **`ETL_PLPGSQL_SEGUROS_G30871276.sql`** — crea todo lo necesario para migrar los datos de la fuente al Data Warehouse.
5. Ejecutar la migración llamando a:
   ```sql
   CALL seguro_dw_g30871276.sp_ejecutar_etl();
   ```
   Se puede correr las veces que se quiera: cada corrida solo trae lo nuevo, actualiza lo que cambió, y no duplica nada.
6. **Cargar las metas desde Excel.** Las metas anuales estan en un archivo excel en la carpeta `Integracion Excel Metas/Metas_Seguros.xlsx`. Para traerlas al Data Warehouse hay un script de Python (`sync_metas_excel.py`) con su propia guía completa en **`Configuracion_Script_Python.md`** — instalación, cómo conectarlo a la base y cómo dejarlo corriendo automáticamente ante cambios en el Excel.


