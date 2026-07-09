-- ============================================================================
--  ETL SEGUROS ALTA VISTA  -  PROYECTO BI FASE II - PUNTO 3
--  Implementacion en lenguaje procedimental PL/pgSQL (PostgreSQL)
--  Fuente:  seguro_g30871276      ->      Almacen:  seguro_dw_g30871276
--  Panza / Mejia / De Sousa
-- ----------------------------------------------------------------------------
--  Que es este archivo:
--    El proceso de Extraccion, Transformacion y Carga (ETL) escrito como
--    PROCEDIMIENTOS ALMACENADOS. Cada dimension y cada hecho tiene su propio
--    procedimiento; un procedimiento ORQUESTADOR (sp_ejecutar_etl) los invoca
--    en el orden correcto -es el equivalente en codigo al "Job" de Pentaho-.
--
--  Patrones aplicados:
--    * Dimensiones : SCD Tipo 1. Se recorre la fuente FILA POR FILA con un
--                    CURSOR; si la clave natural ya existe se hace UPDATE, si no,
--                    se calcula la clave subrogada (SK = maximo actual + 1) e INSERT.
--    * DIM_TIEMPO  : GENERADA, no extraida. Bucle WHILE dia a dia 2018-2031.
--    * Hechos      : CARGA INCREMENTAL (patron Merge + Synchronize de la catedra),
--                    NO full refresh. Por cada registro de la fuente:
--                      - se resuelven las SK con lookups,
--                      - UPSERT por la CLAVE DE NEGOCIO del hecho: si ya existe
--                        una fila con esa clave se ACTUALIZA (medidas/atributos),
--                        si no existe se INSERTA;
--                    y al final un paso de SYNCHRONIZE que ELIMINA del hecho las
--                    filas cuya clave de negocio ya no existe en la fuente.
--                    No se vacia la tabla: solo se aplican las diferencias.
--
--    Claves de negocio usadas para el upsert de cada hecho:
--      FACT_REGISTRO_CONTRATO   : (sk_dim_contrato, sk_dim_producto, sk_dim_cliente)
--      FACT_REGISTRO_SINIESTRO  : (sk_dim_siniestro, sk_dim_contrato)
--      FACT_EVALUACION_SERVICIO : (sk_dim_cliente, sk_dim_producto)
--      FACT_METAS               : (sk_dim_fecha_inicio_meta, sk_dim_producto)
--
--    * Miembro por defecto -1 "NO APLICA" (patron Kimball) para las FK de los
--      hechos que no aplican al grano (FACT_METAS).
--
--  Como ejecutarlo:
--    1) Requiere la fuente y el DW creados (puntos 1 y 2).
--    2) Ejecutar este archivo completo (crea/reemplaza los procedimientos).
--    3) Lanzar la carga con:   CALL seguro_dw_g30871276.sp_ejecutar_etl();
--
--  Idempotente: puede ejecutarse varias veces; los conteos no cambian.
--  Incremental: si cambian los datos de la fuente, la siguiente corrida solo
--               inserta lo nuevo, actualiza lo modificado y borra lo eliminado.
-- ============================================================================

SET search_path TO seguro_dw_g30871276;


-- ============================================================================
--  1. DIM_TIEMPO  (generada con un bucle dia a dia)
--     Convencion dia_semana: 1=Domingo ... 7=Sabado (misma que Pentaho).
-- ============================================================================
CREATE OR REPLACE PROCEDURE seguro_dw_g30871276.sp_cargar_dim_tiempo()
LANGUAGE plpgsql
AS $$
DECLARE
    c_fecha_ini CONSTANT DATE := DATE '2018-01-01';
    c_fecha_fin CONSTANT DATE := DATE '2031-12-31';
    v_fecha     DATE;
    v_sk        INTEGER;
    v_dow       INTEGER;
    v_mes       INTEGER;
    v_insertadas INTEGER := 0;
    c_dias      CONSTANT TEXT[] := ARRAY['Domingo','Lunes','Martes','Miercoles','Jueves','Viernes','Sabado'];
    c_dias_cor  CONSTANT TEXT[] := ARRAY['Dom','Lun','Mar','Mie','Jue','Vie','Sab'];
    c_meses     CONSTANT TEXT[] := ARRAY['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
    c_meses_cor CONSTANT TEXT[] := ARRAY['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
BEGIN
    RAISE NOTICE '-> DIM_TIEMPO: generando calendario % a %', c_fecha_ini, c_fecha_fin;
    SELECT COALESCE(MAX(sk_dim_tiempo), 0) INTO v_sk FROM seguro_dw_g30871276.dim_tiempo;

    v_fecha := c_fecha_ini;
    WHILE v_fecha <= c_fecha_fin LOOP
        IF NOT EXISTS (SELECT 1 FROM seguro_dw_g30871276.dim_tiempo t
                       WHERE t.fecha_completa = v_fecha) THEN
            v_dow := EXTRACT(DOW   FROM v_fecha)::int;
            v_mes := EXTRACT(MONTH FROM v_fecha)::int;
            v_sk  := v_sk + 1;
            INSERT INTO seguro_dw_g30871276.dim_tiempo
                  (sk_dim_tiempo, cod_annio, cod_mes, cod_dia_annio, cod_dia_mes,
                   cod_dia_semana, cod_semana, desc_dia_semana, desc_dia_semana_corta,
                   desc_mes, desc_mes_corta, desc_trimestre, desc_semestre, fecha_completa)
            VALUES
                  (v_sk,
                   EXTRACT(YEAR FROM v_fecha)::int, v_mes,
                   EXTRACT(DOY  FROM v_fecha)::int, EXTRACT(DAY FROM v_fecha)::int,
                   v_dow + 1, EXTRACT(WEEK FROM v_fecha)::int,
                   c_dias[v_dow + 1], c_dias_cor[v_dow + 1],
                   c_meses[v_mes], c_meses_cor[v_mes],
                   'Q' || EXTRACT(QUARTER FROM v_fecha)::int,
                   CASE WHEN v_mes <= 6 THEN 'S1' ELSE 'S2' END,
                   v_fecha);
            v_insertadas := v_insertadas + 1;
        END IF;
        v_fecha := v_fecha + 1;
    END LOOP;

    RAISE NOTICE '   DIM_TIEMPO: % filas nuevas (total %).',
                 v_insertadas, (SELECT COUNT(*) FROM seguro_dw_g30871276.dim_tiempo);
END;
$$;


-- ============================================================================
--  2. DIM_CLIENTE  (SCD1 por cod_cliente_nk) + miembro -1
-- ============================================================================
CREATE OR REPLACE PROCEDURE seguro_dw_g30871276.sp_cargar_dim_cliente()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD; v_sk INTEGER; v_altas INTEGER := 0; v_cambios INTEGER := 0;
BEGIN
    RAISE NOTICE '-> DIM_CLIENTE (SCD1)';
    SELECT COALESCE(MAX(sk_dim_cliente), 0) INTO v_sk
    FROM seguro_dw_g30871276.dim_cliente WHERE sk_dim_cliente > 0;

    FOR r IN SELECT cod_cliente, nb_cliente, ci_rif, telefono, direccion, sexo, email
             FROM seguro_g30871276.cliente ORDER BY cod_cliente
    LOOP
        IF EXISTS (SELECT 1 FROM seguro_dw_g30871276.dim_cliente WHERE cod_cliente_nk = r.cod_cliente) THEN
            UPDATE seguro_dw_g30871276.dim_cliente
               SET nb_cliente = r.nb_cliente, ci_rif = r.ci_rif, telefono = r.telefono,
                   direccion = r.direccion, sexo = r.sexo, email = r.email
             WHERE cod_cliente_nk = r.cod_cliente;
            v_cambios := v_cambios + 1;
        ELSE
            v_sk := v_sk + 1;
            INSERT INTO seguro_dw_g30871276.dim_cliente
                  (sk_dim_cliente, cod_cliente_nk, nb_cliente, ci_rif, telefono, direccion, sexo, email)
            VALUES (v_sk, r.cod_cliente, r.nb_cliente, r.ci_rif, r.telefono, r.direccion, r.sexo, r.email);
            v_altas := v_altas + 1;
        END IF;
    END LOOP;

    IF NOT EXISTS (SELECT 1 FROM seguro_dw_g30871276.dim_cliente WHERE sk_dim_cliente = -1) THEN
        INSERT INTO seguro_dw_g30871276.dim_cliente
              (sk_dim_cliente, cod_cliente_nk, nb_cliente, ci_rif, telefono, direccion, sexo, email)
        VALUES (-1, -1, 'NO APLICA', 'N/A', NULL, NULL, NULL, NULL);
    END IF;

    RAISE NOTICE '   DIM_CLIENTE: % altas, % actualizaciones.', v_altas, v_cambios;
END;
$$;


-- ============================================================================
--  3. DIM_PRODUCTO  (desnormaliza PRODUCTO + TIPO_PRODUCTO; SCD1)
-- ============================================================================
CREATE OR REPLACE PROCEDURE seguro_dw_g30871276.sp_cargar_dim_producto()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD; v_sk INTEGER; v_altas INTEGER := 0; v_cambios INTEGER := 0;
BEGIN
    RAISE NOTICE '-> DIM_PRODUCTO (SCD1)';
    SELECT COALESCE(MAX(sk_dim_producto), 0) INTO v_sk
    FROM seguro_dw_g30871276.dim_producto WHERE sk_dim_producto > 0;

    FOR r IN SELECT p.cod_producto, p.nb_producto, p.descripcion, p.calificacion,
                    p.cod_tipo_producto, tp.nb_tipo_producto
             FROM seguro_g30871276.producto p
             JOIN seguro_g30871276.tipo_producto tp ON tp.cod_tipo_producto = p.cod_tipo_producto
             ORDER BY p.cod_producto
    LOOP
        IF EXISTS (SELECT 1 FROM seguro_dw_g30871276.dim_producto WHERE cod_producto_nk = r.cod_producto) THEN
            UPDATE seguro_dw_g30871276.dim_producto
               SET nb_producto = r.nb_producto, descrip_producto = r.descripcion,
                   cod_tipo_producto = r.cod_tipo_producto::varchar,
                   nb_tipo_producto = r.nb_tipo_producto, calificacion = r.calificacion
             WHERE cod_producto_nk = r.cod_producto;
            v_cambios := v_cambios + 1;
        ELSE
            v_sk := v_sk + 1;
            INSERT INTO seguro_dw_g30871276.dim_producto
                  (sk_dim_producto, cod_producto_nk, nb_producto, descrip_producto,
                   cod_tipo_producto, nb_tipo_producto, calificacion)
            VALUES (v_sk, r.cod_producto, r.nb_producto, r.descripcion,
                    r.cod_tipo_producto::varchar, r.nb_tipo_producto, r.calificacion);
            v_altas := v_altas + 1;
        END IF;
    END LOOP;

    RAISE NOTICE '   DIM_PRODUCTO: % altas, % actualizaciones.', v_altas, v_cambios;
END;
$$;


-- ============================================================================
--  4. DIM_CONTRATO  (SCD1 por nro_contrato_nk) + miembro -1
-- ============================================================================
CREATE OR REPLACE PROCEDURE seguro_dw_g30871276.sp_cargar_dim_contrato()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD; v_sk INTEGER; v_altas INTEGER := 0; v_cambios INTEGER := 0;
BEGIN
    RAISE NOTICE '-> DIM_CONTRATO (SCD1)';
    SELECT COALESCE(MAX(sk_dim_contrato), 0) INTO v_sk
    FROM seguro_dw_g30871276.dim_contrato WHERE sk_dim_contrato > 0;

    FOR r IN SELECT nro_contrato, descrip_contrato
             FROM seguro_g30871276.contrato ORDER BY nro_contrato
    LOOP
        IF EXISTS (SELECT 1 FROM seguro_dw_g30871276.dim_contrato WHERE nro_contrato_nk = r.nro_contrato) THEN
            UPDATE seguro_dw_g30871276.dim_contrato
               SET descrip_contrato = r.descrip_contrato WHERE nro_contrato_nk = r.nro_contrato;
            v_cambios := v_cambios + 1;
        ELSE
            v_sk := v_sk + 1;
            INSERT INTO seguro_dw_g30871276.dim_contrato (sk_dim_contrato, nro_contrato_nk, descrip_contrato)
            VALUES (v_sk, r.nro_contrato, r.descrip_contrato);
            v_altas := v_altas + 1;
        END IF;
    END LOOP;

    IF NOT EXISTS (SELECT 1 FROM seguro_dw_g30871276.dim_contrato WHERE sk_dim_contrato = -1) THEN
        INSERT INTO seguro_dw_g30871276.dim_contrato (sk_dim_contrato, nro_contrato_nk, descrip_contrato)
        VALUES (-1, -1, 'NO APLICA');
    END IF;

    RAISE NOTICE '   DIM_CONTRATO: % altas, % actualizaciones.', v_altas, v_cambios;
END;
$$;


-- ============================================================================
--  5. DIM_ESTADO_CONTRATO  (dominio fijo)
-- ============================================================================
CREATE OR REPLACE PROCEDURE seguro_dw_g30871276.sp_cargar_dim_estado_contrato()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD; v_sk INTEGER; v_altas INTEGER := 0;
BEGIN
    RAISE NOTICE '-> DIM_ESTADO_CONTRATO (dominio fijo)';
    SELECT COALESCE(MAX(sk_dim_estado_contrato), 0) INTO v_sk FROM seguro_dw_g30871276.dim_estado_contrato;

    FOR r IN SELECT * FROM (VALUES
                ('ACTIVO','Activo'), ('VENCIDO','Vencido'), ('SUSPENDIDO','Suspendido')
             ) AS v(cod_estado, descrip_estado)
    LOOP
        IF NOT EXISTS (SELECT 1 FROM seguro_dw_g30871276.dim_estado_contrato WHERE cod_estado = r.cod_estado) THEN
            v_sk := v_sk + 1;
            INSERT INTO seguro_dw_g30871276.dim_estado_contrato (sk_dim_estado_contrato, cod_estado, descrip_estado)
            VALUES (v_sk, r.cod_estado, r.descrip_estado);
            v_altas := v_altas + 1;
        END IF;
    END LOOP;

    RAISE NOTICE '   DIM_ESTADO_CONTRATO: % altas.', v_altas;
END;
$$;


-- ============================================================================
--  6. DIM_EVALUACION_SERVICIO  (SCD1 por cod_evaluacion_nk)
-- ============================================================================
CREATE OR REPLACE PROCEDURE seguro_dw_g30871276.sp_cargar_dim_evaluacion_servicio()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD; v_sk INTEGER; v_altas INTEGER := 0; v_cambios INTEGER := 0;
BEGIN
    RAISE NOTICE '-> DIM_EVALUACION_SERVICIO (SCD1)';
    SELECT COALESCE(MAX(sk_dim_evaluacion), 0) INTO v_sk FROM seguro_dw_g30871276.dim_evaluacion_servicio;

    FOR r IN SELECT cod_evaluacion_servicio, nb_descripcion
             FROM seguro_g30871276.evaluacion_servicio ORDER BY cod_evaluacion_servicio
    LOOP
        IF EXISTS (SELECT 1 FROM seguro_dw_g30871276.dim_evaluacion_servicio WHERE cod_evaluacion_nk = r.cod_evaluacion_servicio) THEN
            UPDATE seguro_dw_g30871276.dim_evaluacion_servicio
               SET nb_descrip = r.nb_descripcion WHERE cod_evaluacion_nk = r.cod_evaluacion_servicio;
            v_cambios := v_cambios + 1;
        ELSE
            v_sk := v_sk + 1;
            INSERT INTO seguro_dw_g30871276.dim_evaluacion_servicio (sk_dim_evaluacion, cod_evaluacion_nk, nb_descrip)
            VALUES (v_sk, r.cod_evaluacion_servicio, r.nb_descripcion);
            v_altas := v_altas + 1;
        END IF;
    END LOOP;

    RAISE NOTICE '   DIM_EVALUACION_SERVICIO: % altas, % actualizaciones.', v_altas, v_cambios;
END;
$$;


-- ============================================================================
--  7. DIM_SUCURSAL  (desnormaliza SUCURSAL + CIUDAD + PAIS; SCD1)
-- ============================================================================
CREATE OR REPLACE PROCEDURE seguro_dw_g30871276.sp_cargar_dim_sucursal()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD; v_sk INTEGER; v_altas INTEGER := 0; v_cambios INTEGER := 0;
BEGIN
    RAISE NOTICE '-> DIM_SUCURSAL (SCD1)';
    SELECT COALESCE(MAX(sk_dim_sucursal), 0) INTO v_sk FROM seguro_dw_g30871276.dim_sucursal;

    FOR r IN SELECT su.cod_sucursal, su.nb_sucursal, ci.cod_ciudad, ci.nb_ciudad, pa.cod_pais, pa.nb_pais
             FROM seguro_g30871276.sucursal su
             JOIN seguro_g30871276.ciudad ci ON ci.cod_ciudad = su.cod_ciudad
             JOIN seguro_g30871276.pais  pa ON pa.cod_pais  = ci.cod_pais
             ORDER BY su.cod_sucursal
    LOOP
        IF EXISTS (SELECT 1 FROM seguro_dw_g30871276.dim_sucursal WHERE cod_sucursal_nk = r.cod_sucursal) THEN
            UPDATE seguro_dw_g30871276.dim_sucursal
               SET nb_sucursal = r.nb_sucursal, cod_ciudad = r.cod_ciudad, nb_ciudad = r.nb_ciudad,
                   cod_pais = r.cod_pais, nb_pais = r.nb_pais
             WHERE cod_sucursal_nk = r.cod_sucursal;
            v_cambios := v_cambios + 1;
        ELSE
            v_sk := v_sk + 1;
            INSERT INTO seguro_dw_g30871276.dim_sucursal
                  (sk_dim_sucursal, cod_sucursal_nk, nb_sucursal, cod_ciudad, nb_ciudad, cod_pais, nb_pais)
            VALUES (v_sk, r.cod_sucursal, r.nb_sucursal, r.cod_ciudad, r.nb_ciudad, r.cod_pais, r.nb_pais);
            v_altas := v_altas + 1;
        END IF;
    END LOOP;

    RAISE NOTICE '   DIM_SUCURSAL: % altas, % actualizaciones.', v_altas, v_cambios;
END;
$$;


-- ============================================================================
--  8. DIM_SINIESTRO  (SCD1 por nro_siniestro_nk)
-- ============================================================================
CREATE OR REPLACE PROCEDURE seguro_dw_g30871276.sp_cargar_dim_siniestro()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD; v_sk INTEGER; v_altas INTEGER := 0; v_cambios INTEGER := 0;
BEGIN
    RAISE NOTICE '-> DIM_SINIESTRO (SCD1)';
    SELECT COALESCE(MAX(sk_dim_siniestro), 0) INTO v_sk FROM seguro_dw_g30871276.dim_siniestro;

    FOR r IN SELECT nro_siniestro, descripcion_siniestro
             FROM seguro_g30871276.siniestro ORDER BY nro_siniestro
    LOOP
        IF EXISTS (SELECT 1 FROM seguro_dw_g30871276.dim_siniestro WHERE nro_siniestro_nk = r.nro_siniestro) THEN
            UPDATE seguro_dw_g30871276.dim_siniestro
               SET descrip_siniestro = r.descripcion_siniestro WHERE nro_siniestro_nk = r.nro_siniestro;
            v_cambios := v_cambios + 1;
        ELSE
            v_sk := v_sk + 1;
            INSERT INTO seguro_dw_g30871276.dim_siniestro (sk_dim_siniestro, nro_siniestro_nk, descrip_siniestro)
            VALUES (v_sk, r.nro_siniestro, r.descripcion_siniestro);
            v_altas := v_altas + 1;
        END IF;
    END LOOP;

    RAISE NOTICE '   DIM_SINIESTRO: % altas, % actualizaciones.', v_altas, v_cambios;
END;
$$;


-- ============================================================================
--  9. FACT_REGISTRO_CONTRATO  (INCREMENTAL: upsert + synchronize)
--     Clave de negocio: (sk_dim_contrato, sk_dim_producto, sk_dim_cliente)
--     Sucursal del hecho = sucursal de captacion del cliente.
-- ============================================================================
CREATE OR REPLACE PROCEDURE seguro_dw_g30871276.sp_cargar_fact_registro_contrato()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
    v_sk_ini INTEGER; v_sk_fin INTEGER; v_sk_cli INTEGER; v_sk_con INTEGER;
    v_sk_pro INTEGER; v_sk_est INTEGER; v_sk_suc INTEGER;
    v_altas INTEGER := 0; v_cambios INTEGER := 0; v_borradas INTEGER := 0;
BEGIN
    RAISE NOTICE '-> FACT_REGISTRO_CONTRATO (incremental: upsert + synchronize)';

    FOR r IN SELECT rc.nro_contrato, rc.cod_producto, rc.cod_cliente,
                    rc.fecha_inicio, rc.fecha_fin, rc.monto, rc.estado_contrato, cl.cod_sucursal
             FROM seguro_g30871276.registro_contrato rc
             JOIN seguro_g30871276.cliente cl ON cl.cod_cliente = rc.cod_cliente
    LOOP
        SELECT sk_dim_tiempo INTO v_sk_ini FROM seguro_dw_g30871276.dim_tiempo WHERE fecha_completa = r.fecha_inicio;
        SELECT sk_dim_tiempo INTO v_sk_fin FROM seguro_dw_g30871276.dim_tiempo WHERE fecha_completa = r.fecha_fin;
        SELECT sk_dim_cliente INTO v_sk_cli FROM seguro_dw_g30871276.dim_cliente WHERE cod_cliente_nk = r.cod_cliente;
        SELECT sk_dim_contrato INTO v_sk_con FROM seguro_dw_g30871276.dim_contrato WHERE nro_contrato_nk = r.nro_contrato;
        SELECT sk_dim_producto INTO v_sk_pro FROM seguro_dw_g30871276.dim_producto WHERE cod_producto_nk = r.cod_producto;
        SELECT sk_dim_estado_contrato INTO v_sk_est FROM seguro_dw_g30871276.dim_estado_contrato WHERE cod_estado = UPPER(r.estado_contrato);
        SELECT sk_dim_sucursal INTO v_sk_suc FROM seguro_dw_g30871276.dim_sucursal WHERE cod_sucursal_nk = r.cod_sucursal;

        -- UPSERT por clave de negocio
        UPDATE seguro_dw_g30871276.fact_registro_contrato
           SET sk_dim_tiempo_fecha_inicio = v_sk_ini, sk_dim_tiempo_fecha_fin = v_sk_fin,
               sk_dim_estado_contrato = v_sk_est, sk_dim_sucursal = v_sk_suc,
               monto = r.monto, cantidad = 1, cantidad_cliente = 1,
               cantidad_producto = 1, cantidad_contrato = 1
         WHERE sk_dim_contrato = v_sk_con AND sk_dim_producto = v_sk_pro AND sk_dim_cliente = v_sk_cli;

        IF NOT FOUND THEN
            INSERT INTO seguro_dw_g30871276.fact_registro_contrato
                  (sk_dim_tiempo_fecha_inicio, sk_dim_tiempo_fecha_fin, sk_dim_cliente,
                   sk_dim_contrato, sk_dim_producto, sk_dim_estado_contrato, sk_dim_sucursal,
                   monto, cantidad, cantidad_cliente, cantidad_producto, cantidad_contrato)
            VALUES (v_sk_ini, v_sk_fin, v_sk_cli, v_sk_con, v_sk_pro, v_sk_est, v_sk_suc, r.monto, 1, 1, 1, 1);
            v_altas := v_altas + 1;
        ELSE
            v_cambios := v_cambios + 1;
        END IF;
    END LOOP;

    -- SYNCHRONIZE: eliminar hechos cuya clave de negocio ya no existe en la fuente
    DELETE FROM seguro_dw_g30871276.fact_registro_contrato f
    WHERE NOT EXISTS (
        SELECT 1 FROM seguro_g30871276.registro_contrato rc
        JOIN seguro_dw_g30871276.dim_contrato dk ON dk.nro_contrato_nk = rc.nro_contrato
        JOIN seguro_dw_g30871276.dim_producto dp ON dp.cod_producto_nk = rc.cod_producto
        JOIN seguro_dw_g30871276.dim_cliente  dc ON dc.cod_cliente_nk  = rc.cod_cliente
        WHERE dk.sk_dim_contrato = f.sk_dim_contrato
          AND dp.sk_dim_producto = f.sk_dim_producto
          AND dc.sk_dim_cliente  = f.sk_dim_cliente);
    GET DIAGNOSTICS v_borradas = ROW_COUNT;

    RAISE NOTICE '   FACT_REGISTRO_CONTRATO: % altas, % actualizaciones, % eliminadas.',
                 v_altas, v_cambios, v_borradas;
END;
$$;


-- ============================================================================
--  10. FACT_REGISTRO_SINIESTRO  (INCREMENTAL: upsert + synchronize)
--      Clave de negocio: (sk_dim_siniestro, sk_dim_contrato)
--      Cliente/producto se derivan del contrato; sucursal, del cliente.
--      sk_fecha_respuesta = NULL si el siniestro aun no tiene respuesta.
-- ============================================================================
CREATE OR REPLACE PROCEDURE seguro_dw_g30871276.sp_cargar_fact_registro_siniestro()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
    v_sk_sin INTEGER; v_sk_resp INTEGER; v_sk_cli INTEGER; v_sk_con INTEGER;
    v_sk_suc INTEGER; v_sk_pro INTEGER; v_sk_tsin INTEGER;
    v_altas INTEGER := 0; v_cambios INTEGER := 0; v_borradas INTEGER := 0;
BEGIN
    RAISE NOTICE '-> FACT_REGISTRO_SINIESTRO (incremental: upsert + synchronize)';

    FOR r IN SELECT rs.nro_siniestro, rs.nro_contrato, rs.fecha_siniestro, rs.fecha_respuesta,
                    rs.monto_reconocido, rs.monto_solicitado, rs.id_rechazo,
                    rc.cod_cliente, rc.cod_producto, cl.cod_sucursal
             FROM seguro_g30871276.registro_siniestro rs
             JOIN seguro_g30871276.registro_contrato rc ON rc.nro_contrato = rs.nro_contrato
             JOIN seguro_g30871276.cliente cl ON cl.cod_cliente = rc.cod_cliente
    LOOP
        SELECT sk_dim_tiempo INTO v_sk_sin FROM seguro_dw_g30871276.dim_tiempo WHERE fecha_completa = r.fecha_siniestro;
        IF r.fecha_respuesta IS NULL THEN
            v_sk_resp := NULL;
        ELSE
            SELECT sk_dim_tiempo INTO v_sk_resp FROM seguro_dw_g30871276.dim_tiempo WHERE fecha_completa = r.fecha_respuesta;
        END IF;
        SELECT sk_dim_cliente  INTO v_sk_cli  FROM seguro_dw_g30871276.dim_cliente  WHERE cod_cliente_nk  = r.cod_cliente;
        SELECT sk_dim_contrato INTO v_sk_con  FROM seguro_dw_g30871276.dim_contrato WHERE nro_contrato_nk = r.nro_contrato;
        SELECT sk_dim_sucursal INTO v_sk_suc  FROM seguro_dw_g30871276.dim_sucursal WHERE cod_sucursal_nk = r.cod_sucursal;
        SELECT sk_dim_producto INTO v_sk_pro  FROM seguro_dw_g30871276.dim_producto WHERE cod_producto_nk = r.cod_producto;
        SELECT sk_dim_siniestro INTO v_sk_tsin FROM seguro_dw_g30871276.dim_siniestro WHERE nro_siniestro_nk = r.nro_siniestro;

        UPDATE seguro_dw_g30871276.fact_registro_siniestro
           SET sk_fecha_siniestro = v_sk_sin, sk_fecha_respuesta = v_sk_resp,
               sk_dim_cliente = v_sk_cli, sk_dim_sucursal = v_sk_suc, sk_dim_producto = v_sk_pro,
               cantidad = 1, monto_reconocido = r.monto_reconocido,
               monto_solicitado = r.monto_solicitado, id_rechazo = r.id_rechazo
         WHERE sk_dim_siniestro = v_sk_tsin AND sk_dim_contrato = v_sk_con;

        IF NOT FOUND THEN
            INSERT INTO seguro_dw_g30871276.fact_registro_siniestro
                  (sk_fecha_siniestro, sk_fecha_respuesta, sk_dim_cliente, sk_dim_contrato,
                   sk_dim_sucursal, sk_dim_producto, sk_dim_siniestro,
                   cantidad, monto_reconocido, monto_solicitado, id_rechazo)
            VALUES (v_sk_sin, v_sk_resp, v_sk_cli, v_sk_con, v_sk_suc, v_sk_pro, v_sk_tsin,
                    1, r.monto_reconocido, r.monto_solicitado, r.id_rechazo);
            v_altas := v_altas + 1;
        ELSE
            v_cambios := v_cambios + 1;
        END IF;
    END LOOP;

    DELETE FROM seguro_dw_g30871276.fact_registro_siniestro f
    WHERE NOT EXISTS (
        SELECT 1 FROM seguro_g30871276.registro_siniestro rs
        JOIN seguro_dw_g30871276.dim_siniestro dsi ON dsi.nro_siniestro_nk = rs.nro_siniestro
        JOIN seguro_dw_g30871276.dim_contrato  dk  ON dk.nro_contrato_nk  = rs.nro_contrato
        WHERE dsi.sk_dim_siniestro = f.sk_dim_siniestro
          AND dk.sk_dim_contrato   = f.sk_dim_contrato);
    GET DIAGNOSTICS v_borradas = ROW_COUNT;

    RAISE NOTICE '   FACT_REGISTRO_SINIESTRO: % altas, % actualizaciones, % eliminadas.',
                 v_altas, v_cambios, v_borradas;
END;
$$;


-- ============================================================================
--  11. FACT_EVALUACION_SERVICIO  (INCREMENTAL: upsert + synchronize)
--      Clave de negocio: (sk_dim_cliente, sk_dim_producto)
--      Fecha de evaluacion = fecha_fin del ULTIMO contrato del par (cliente,producto).
--      Filtro de calidad: si el par no tiene contrato, se descarta la evaluacion.
--      recomienda_amigo: SI -> 1.00, NO -> 0.00.
-- ============================================================================
CREATE OR REPLACE PROCEDURE seguro_dw_g30871276.sp_cargar_fact_evaluacion_servicio()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD; v_fecha_eval DATE;
    v_sk_tiempo INTEGER; v_sk_cli INTEGER; v_sk_pro INTEGER; v_sk_eval INTEGER;
    v_reco NUMERIC(5,2);
    v_altas INTEGER := 0; v_cambios INTEGER := 0; v_borradas INTEGER := 0; v_descartadas INTEGER := 0;
BEGIN
    RAISE NOTICE '-> FACT_EVALUACION_SERVICIO (incremental: upsert + synchronize)';

    FOR r IN SELECT cod_cliente, cod_producto, cod_evaluacion_servicio, recomienda_amigo
             FROM seguro_g30871276.recomienda
    LOOP
        SELECT MAX(rc.fecha_fin) INTO v_fecha_eval
        FROM   seguro_g30871276.registro_contrato rc
        WHERE  rc.cod_cliente = r.cod_cliente AND rc.cod_producto = r.cod_producto;

        IF v_fecha_eval IS NULL THEN
            v_descartadas := v_descartadas + 1;
            CONTINUE;
        END IF;

        SELECT sk_dim_tiempo INTO v_sk_tiempo FROM seguro_dw_g30871276.dim_tiempo WHERE fecha_completa = v_fecha_eval;
        SELECT sk_dim_cliente INTO v_sk_cli FROM seguro_dw_g30871276.dim_cliente WHERE cod_cliente_nk = r.cod_cliente;
        SELECT sk_dim_producto INTO v_sk_pro FROM seguro_dw_g30871276.dim_producto WHERE cod_producto_nk = r.cod_producto;
        SELECT sk_dim_evaluacion INTO v_sk_eval FROM seguro_dw_g30871276.dim_evaluacion_servicio WHERE cod_evaluacion_nk = r.cod_evaluacion_servicio;

        v_reco := CASE WHEN UPPER(r.recomienda_amigo) = 'SI' THEN 1.00 ELSE 0.00 END;

        UPDATE seguro_dw_g30871276.fact_evaluacion_servicio
           SET sk_dim_tiempo_evaluacion = v_sk_tiempo, sk_dim_evaluacion_servicio = v_sk_eval,
               cantidad = 1, recomienda_amigo = v_reco
         WHERE sk_dim_cliente = v_sk_cli AND sk_dim_producto = v_sk_pro;

        IF NOT FOUND THEN
            INSERT INTO seguro_dw_g30871276.fact_evaluacion_servicio
                  (sk_dim_tiempo_evaluacion, sk_dim_cliente, sk_dim_producto,
                   sk_dim_evaluacion_servicio, cantidad, recomienda_amigo)
            VALUES (v_sk_tiempo, v_sk_cli, v_sk_pro, v_sk_eval, 1, v_reco);
            v_altas := v_altas + 1;
        ELSE
            v_cambios := v_cambios + 1;
        END IF;
    END LOOP;

    -- SYNCHRONIZE: eliminar evaluaciones cuyo par (cliente,producto) ya no exista
    -- en la fuente con contrato valido (incluye las que se volvieron huerfanas).
    DELETE FROM seguro_dw_g30871276.fact_evaluacion_servicio f
    WHERE NOT EXISTS (
        SELECT 1 FROM seguro_g30871276.recomienda rr
        JOIN seguro_dw_g30871276.dim_cliente  dc ON dc.cod_cliente_nk  = rr.cod_cliente
        JOIN seguro_dw_g30871276.dim_producto dp ON dp.cod_producto_nk = rr.cod_producto
        WHERE dc.sk_dim_cliente = f.sk_dim_cliente
          AND dp.sk_dim_producto = f.sk_dim_producto
          AND EXISTS (SELECT 1 FROM seguro_g30871276.registro_contrato rc
                      WHERE rc.cod_cliente = rr.cod_cliente AND rc.cod_producto = rr.cod_producto));
    GET DIAGNOSTICS v_borradas = ROW_COUNT;

    RAISE NOTICE '   FACT_EVALUACION_SERVICIO: % altas, % actualizaciones, % eliminadas (% descartadas por calidad).',
                 v_altas, v_cambios, v_borradas, v_descartadas;
END;
$$;


-- ============================================================================
--  12. FACT_METAS  (INCREMENTAL: upsert + synchronize)
--      Clave de negocio: (sk_dim_fecha_inicio_meta, sk_dim_producto)
--      Fuente real: hoja Excel de la Gerencia de Estadistica (Metas_Seguros.xlsx).
--      Las 50 metas se cargan en una tabla temporal y desde ahi se hace el
--      upsert/synchronize (grano: meta anual por producto; cliente y contrato -1).
-- ============================================================================
CREATE OR REPLACE PROCEDURE seguro_dw_g30871276.sp_cargar_fact_metas()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD; v_sk_ini INTEGER; v_sk_fin INTEGER; v_sk_pro INTEGER;
    v_altas INTEGER := 0; v_cambios INTEGER := 0; v_borradas INTEGER := 0;
BEGIN
    RAISE NOTICE '-> FACT_METAS (incremental: upsert + synchronize)';

    -- Cargar las metas (origen: hoja Excel) en una tabla temporal
    DROP TABLE IF EXISTS tmp_metas;
    CREATE TEMP TABLE tmp_metas (anio int, cod_producto int, monto numeric(18,2), meta_ren int, meta_aseg int);
    INSERT INTO tmp_metas VALUES
        (2022,1,260.00,1,2),(2022,2,960.00,1,1),(2022,3,585.00,1,2),(2022,4,144.00,1,1),(2022,5,390.00,1,2),
        (2022,6,2000.00,1,1),(2022,7,195.00,1,2),(2022,8,640.00,1,1),(2022,9,780.00,1,2),(2022,10,96.00,1,1),
        (2023,1,160.00,1,1),(2023,2,1560.00,1,2),(2023,3,360.00,1,1),(2023,4,234.00,1,2),(2023,5,240.00,1,1),
        (2023,6,3250.00,1,2),(2023,7,120.00,1,1),(2023,8,1040.00,1,2),(2023,9,480.00,1,1),(2023,10,156.00,1,2),
        (2024,1,260.00,1,2),(2024,2,960.00,1,1),(2024,3,585.00,1,2),(2024,4,144.00,1,1),(2024,5,390.00,1,2),
        (2024,6,2000.00,1,1),(2024,7,195.00,1,2),(2024,8,640.00,1,1),(2024,9,780.00,1,2),(2024,10,96.00,1,1),
        (2025,1,160.00,1,1),(2025,2,1560.00,1,2),(2025,3,360.00,1,1),(2025,4,234.00,1,2),(2025,5,240.00,1,1),
        (2025,6,3250.00,1,2),(2025,7,120.00,1,1),(2025,8,1040.00,1,2),(2025,9,480.00,1,1),(2025,10,156.00,1,2),
        (2026,1,260.00,1,2),(2026,2,960.00,1,1),(2026,3,585.00,1,2),(2026,4,144.00,1,1),(2026,5,390.00,1,2),
        (2026,6,2000.00,1,1),(2026,7,195.00,1,2),(2026,8,640.00,1,1),(2026,9,780.00,1,2),(2026,10,96.00,1,1);

    FOR r IN SELECT anio, cod_producto, monto, meta_ren, meta_aseg FROM tmp_metas
    LOOP
        SELECT sk_dim_tiempo INTO v_sk_ini FROM seguro_dw_g30871276.dim_tiempo WHERE fecha_completa = MAKE_DATE(r.anio, 1, 1);
        SELECT sk_dim_tiempo INTO v_sk_fin FROM seguro_dw_g30871276.dim_tiempo WHERE fecha_completa = MAKE_DATE(r.anio, 12, 31);
        SELECT sk_dim_producto INTO v_sk_pro FROM seguro_dw_g30871276.dim_producto WHERE cod_producto_nk = r.cod_producto;

        UPDATE seguro_dw_g30871276.fact_metas
           SET sk_dim_fecha_fin_meta = v_sk_fin, sk_dim_cliente = -1, sk_dim_contrato = -1,
               monto_meta_ingreso = r.monto, meta_renovacion = r.meta_ren, meta_asegurados = r.meta_aseg
         WHERE sk_dim_fecha_inicio_meta = v_sk_ini AND sk_dim_producto = v_sk_pro;

        IF NOT FOUND THEN
            INSERT INTO seguro_dw_g30871276.fact_metas
                  (sk_dim_fecha_inicio_meta, sk_dim_fecha_fin_meta, sk_dim_cliente,
                   sk_dim_producto, sk_dim_contrato, monto_meta_ingreso, meta_renovacion, meta_asegurados)
            VALUES (v_sk_ini, v_sk_fin, -1, v_sk_pro, -1, r.monto, r.meta_ren, r.meta_aseg);
            v_altas := v_altas + 1;
        ELSE
            v_cambios := v_cambios + 1;
        END IF;
    END LOOP;

    DELETE FROM seguro_dw_g30871276.fact_metas f
    WHERE NOT EXISTS (
        SELECT 1 FROM tmp_metas m
        JOIN seguro_dw_g30871276.dim_tiempo ti ON ti.fecha_completa = MAKE_DATE(m.anio, 1, 1)
        JOIN seguro_dw_g30871276.dim_producto dp ON dp.cod_producto_nk = m.cod_producto
        WHERE ti.sk_dim_tiempo = f.sk_dim_fecha_inicio_meta AND dp.sk_dim_producto = f.sk_dim_producto);
    GET DIAGNOSTICS v_borradas = ROW_COUNT;

    DROP TABLE IF EXISTS tmp_metas;
    RAISE NOTICE '   FACT_METAS: % altas, % actualizaciones, % eliminadas.', v_altas, v_cambios, v_borradas;
END;
$$;


-- ============================================================================
--  ORQUESTADOR  (equivalente al Job de Pentaho)
-- ============================================================================
CREATE OR REPLACE PROCEDURE seguro_dw_g30871276.sp_ejecutar_etl()
LANGUAGE plpgsql
AS $$
DECLARE
    v_inicio TIMESTAMP := clock_timestamp();
BEGIN
    RAISE NOTICE '==================================================================';
    RAISE NOTICE 'INICIO ETL SEGUROS ALTA VISTA  -  %', v_inicio;
    RAISE NOTICE '==================================================================';

    CALL seguro_dw_g30871276.sp_cargar_dim_tiempo();
    CALL seguro_dw_g30871276.sp_cargar_dim_cliente();
    CALL seguro_dw_g30871276.sp_cargar_dim_producto();
    CALL seguro_dw_g30871276.sp_cargar_dim_contrato();
    CALL seguro_dw_g30871276.sp_cargar_dim_estado_contrato();
    CALL seguro_dw_g30871276.sp_cargar_dim_evaluacion_servicio();
    CALL seguro_dw_g30871276.sp_cargar_dim_sucursal();
    CALL seguro_dw_g30871276.sp_cargar_dim_siniestro();

    CALL seguro_dw_g30871276.sp_cargar_fact_registro_contrato();
    CALL seguro_dw_g30871276.sp_cargar_fact_registro_siniestro();
    CALL seguro_dw_g30871276.sp_cargar_fact_evaluacion_servicio();
    CALL seguro_dw_g30871276.sp_cargar_fact_metas();

    RAISE NOTICE '==================================================================';
    RAISE NOTICE 'ETL COMPLETADO OK en % seg.',
                 round(EXTRACT(EPOCH FROM (clock_timestamp() - v_inicio))::numeric, 2);
    RAISE NOTICE '==================================================================';
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'ETL ABORTADO. Error SQLSTATE %: %', SQLSTATE, SQLERRM;
END;
$$;

-- ============================================================================
--  FIN. Para ejecutar la carga:
--      CALL seguro_dw_g30871276.sp_ejecutar_etl();
-- ============================================================================
