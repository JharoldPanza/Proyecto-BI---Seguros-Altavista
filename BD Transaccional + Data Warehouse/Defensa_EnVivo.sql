--  Como usarlo el dia de la defensa:
--    1) Correr la seccion "PASO 0" y dejarla a la vista (captura del estado
--       "antes" de los indicadores que se van a mover: 8, 2, 1, 3, 4, 5, 6 y 7
--       -los 8 del proyecto-).
--    2) Correr "PASO 1" y "PASO 2" (la modificacion de la fuente). El PASO 2
--       tiene 5 escenarios (2A a 2E): usar los que el jurado pida ver, no
--       hace falta correrlos todos.
--    3) Correr "PASO 3" (CALL al ETL) delante del jurado.
--    4) Correr "PASO 4" y mostrar que los mismos indicadores del PASO 0
--       cambiaron de forma coherente, y que los conteos de "no duplicados"
--       dan 1, no 2.
--
--  Guion de negocio de los escenarios (para que se entienda como una
--  historia, no como filas sueltas): un cliente nuevo (Cliente Defensa En
--  Vivo) contrata HCM Premium; sufre un siniestro que es rechazado; como
--  consecuencia, califica el producto bajo y no lo recomendaria. En paralelo,
--  un contrato viejo (Cliente 1) vence, y un siniestro que estaba en proceso
--  finalmente se resuelve.
--
--  Que indicador mueve cada escenario:
--    1A (dimension, cliente nuevo)         -> ninguno todavia, prepara 2A-2E
--    2A (contrato nuevo)                   -> Ind. 8 (monto x sucursal),
--                                              Ind. 6 (ingreso x tipo producto),
--                                              Ind. 5 (cumplimiento de metas)
--    2B (contrato existente ACTIVO->VENCIDO) -> Ind. 2 (contratos por estado)
--    2C (siniestro nuevo, rechazado)        -> Ind. 3 (siniestralidad x producto),
--                                              Ind. 7 (% rechazados),
--                                              Ind. 1 (tiempo de respuesta)
--    2D (siniestro en proceso se resuelve)  -> Ind. 1 (tiempo de respuesta)
--    2E (evaluacion nueva del cliente demo) -> Ind. 4 (calificacion y % recomienda)
--
--  El PASO 5, al final, esta comentado: es el rollback para poder ensayar
--  este script varias veces antes del dia real sin ir arrastrando datos de
--  prueba de un ensayo a otro.


--  PASO 0 (opcional) - Estado "ANTES" de los indicadores que se van a mover
--    Indicador 8 (monto contratado por sucursal) e Indicador 2 (distribucion
--    de contratos por estado).

SELECT su.nb_sucursal, ROUND(SUM(f.monto), 2) AS monto_total
FROM seguro_dw_g30871276.fact_registro_contrato f
JOIN seguro_dw_g30871276.dim_sucursal su ON su.sk_dim_sucursal = f.sk_dim_sucursal
GROUP BY su.nb_sucursal
ORDER BY monto_total DESC;

SELECT ec.descrip_estado, COUNT(*) AS cantidad_contratos
FROM seguro_dw_g30871276.fact_registro_contrato f
JOIN seguro_dw_g30871276.dim_estado_contrato ec ON ec.sk_dim_estado_contrato = f.sk_dim_estado_contrato
GROUP BY ec.descrip_estado
ORDER BY cantidad_contratos DESC;

-- Indicador 1: tiempo promedio de respuesta a siniestros (solo los ya resueltos)
SELECT ROUND(AVG(ti_resp.fecha_completa - ti_sin.fecha_completa), 2) AS dias_promedio_respuesta
FROM seguro_dw_g30871276.fact_registro_siniestro f
JOIN seguro_dw_g30871276.dim_tiempo ti_sin  ON ti_sin.sk_dim_tiempo  = f.sk_fecha_siniestro
JOIN seguro_dw_g30871276.dim_tiempo ti_resp ON ti_resp.sk_dim_tiempo = f.sk_fecha_respuesta;

-- Indicador 3: tasa de siniestralidad por producto (siniestros / contratos)
--   Se pre-agrega cada hecho por separado antes de unir a la dimension para
--   no generar un producto cartesiano entre los dos hechos.
SELECT dp.nb_producto, COALESCE(c.contratos, 0) AS contratos,
       COALESCE(s.siniestros, 0) AS siniestros,
       ROUND(COALESCE(s.siniestros, 0)::numeric / NULLIF(COALESCE(c.contratos, 0), 0), 2) AS tasa_siniestralidad
FROM seguro_dw_g30871276.dim_producto dp
LEFT JOIN (SELECT sk_dim_producto, COUNT(*) AS contratos
           FROM seguro_dw_g30871276.fact_registro_contrato GROUP BY sk_dim_producto) c
       ON c.sk_dim_producto = dp.sk_dim_producto
LEFT JOIN (SELECT sk_dim_producto, COUNT(*) AS siniestros
           FROM seguro_dw_g30871276.fact_registro_siniestro GROUP BY sk_dim_producto) s
       ON s.sk_dim_producto = dp.sk_dim_producto
ORDER BY tasa_siniestralidad DESC NULLS LAST;

-- Indicador 4: calificacion promedio y % que recomienda, por producto
SELECT dp.nb_producto, ROUND(AVG(de.cod_evaluacion_nk), 2) AS calificacion_promedio,
       ROUND(AVG(fe.recomienda_amigo) * 100, 1) AS pct_recomienda
FROM seguro_dw_g30871276.fact_evaluacion_servicio fe
JOIN seguro_dw_g30871276.dim_producto dp ON dp.sk_dim_producto = fe.sk_dim_producto
JOIN seguro_dw_g30871276.dim_evaluacion_servicio de ON de.sk_dim_evaluacion = fe.sk_dim_evaluacion_servicio
GROUP BY dp.nb_producto
ORDER BY calificacion_promedio DESC;

-- Indicador 5: cumplimiento de metas del producto 2 (HCM Premium) para 2026
--   -es donde va a caer el contrato demo del PASO 2A-
SELECT dp.nb_producto, fm.sk_dim_fecha_inicio_meta / 10000 AS anio,
       fm.monto_meta_ingreso, COALESCE(real_ing.monto_real, 0) AS monto_real,
       ROUND(COALESCE(real_ing.monto_real, 0) / NULLIF(fm.monto_meta_ingreso, 0) * 100, 1) AS pct_cumplimiento
FROM seguro_dw_g30871276.fact_metas fm
JOIN seguro_dw_g30871276.dim_producto dp ON dp.sk_dim_producto = fm.sk_dim_producto
LEFT JOIN (SELECT sk_dim_producto, sk_dim_tiempo_fecha_inicio / 10000 AS anio, SUM(monto) AS monto_real
           FROM seguro_dw_g30871276.fact_registro_contrato
           GROUP BY sk_dim_producto, sk_dim_tiempo_fecha_inicio / 10000) real_ing
       ON real_ing.sk_dim_producto = fm.sk_dim_producto
      AND real_ing.anio = fm.sk_dim_fecha_inicio_meta / 10000
WHERE dp.cod_producto_nk = 2 AND fm.sk_dim_fecha_inicio_meta / 10000 = 2026;

-- Indicador 6: ingreso total por tipo de producto
SELECT dp.nb_tipo_producto, ROUND(SUM(f.monto), 2) AS ingreso_total
FROM seguro_dw_g30871276.fact_registro_contrato f
JOIN seguro_dw_g30871276.dim_producto dp ON dp.sk_dim_producto = f.sk_dim_producto
GROUP BY dp.nb_tipo_producto
ORDER BY ingreso_total DESC;

-- Indicador 7: porcentaje de siniestros rechazados (global)
SELECT COUNT(*) FILTER (WHERE id_rechazo = 'SI') AS rechazados, COUNT(*) AS total_siniestros,
       ROUND(COUNT(*) FILTER (WHERE id_rechazo = 'SI')::numeric / COUNT(*) * 100, 1) AS pct_rechazados
FROM seguro_dw_g30871276.fact_registro_siniestro;

-- Confirmar que el cliente demo no existe en el DW
SELECT * FROM seguro_dw_g30871276.dim_cliente WHERE cod_cliente_nk = 26;  -- debe dar 0 filas


--  PASO 1 - Escenario A: nuevo registro en una DIMENSION (cliente nuevo)
--    Sucursal 1 = Alta Vista Caracas. Se ve reflejado en DIM_CLIENTE tras
--    correr el ETL.

INSERT INTO seguro_g30871276.cliente
      (cod_cliente, nb_cliente, ci_rif, telefono, direccion, sexo, email, cod_sucursal)
VALUES
      (26, 'Cliente Defensa En Vivo', 'V-99999999', '0414-9999999',
       'Direccion Demo Defensa, Caracas', 'M', 'defensa.envivo@email.com', 1);


--  PASO 2 - Escenario B: valor nuevo/modificado en la tabla de HECHOS

-- 2A) INSERT: contrato nuevo para el cliente creado justo en el paso 1.
--     Producto 2 = HCM Premium (tipo PERSONALES). 
INSERT INTO seguro_g30871276.contrato (nro_contrato, descrip_contrato)
VALUES (61, 'Poliza Demo Defensa En Vivo - Cliente 26');

INSERT INTO seguro_g30871276.registro_contrato
      (nro_contrato, cod_producto, cod_cliente, fecha_inicio, fecha_fin, monto, estado_contrato)
VALUES
      (61, 2, 26, '2026-07-11', '2027-07-11', 5000.00, 'ACTIVO');

-- 2B) UPDATE (opcional, si se pide ver tambien una MODIFICACION):

-- Registro antes de modificar
select * from seguro_g30871276.registro_contrato
WHERE nro_contrato = 1 AND cod_producto = 2 AND cod_cliente = 1;

-- Update de la modificacion
UPDATE seguro_g30871276.registro_contrato
   SET estado_contrato = 'VENCIDO'
 WHERE nro_contrato = 1 AND cod_producto = 2 AND cod_cliente = 1;

-- 2C) INSERT: siniestro nuevo sobre la poliza demo (contrato 61), rechazado.
--     Mueve el Indicador 3 (siniestralidad de HCM Premium sube), el
--     Indicador 7 (% de rechazados) y aporta un dato mas al Indicador 1
--     (tiempo de respuesta), porque ya viene con fecha_respuesta.
INSERT INTO seguro_g30871276.siniestro (nro_siniestro, descripcion_siniestro)
VALUES (31, 'Siniestro Demo Defensa En Vivo - Rechazado');

INSERT INTO seguro_g30871276.registro_siniestro
      (nro_siniestro, nro_contrato, fecha_siniestro, fecha_respuesta, id_rechazo, monto_reconocido, monto_solicitado)
VALUES
      (31, 61, '2026-08-01', '2026-08-10', 'SI', 0.00, 1200.00);

-- 2D) UPDATE: un siniestro que estaba en proceso (fecha_respuesta NULL)
--     se resuelve. Mueve el Indicador 1 (antes esta fila no
--     entraba en el promedio porque no tenia fecha de respuesta).
--     Registro antes de modificar:
SELECT * FROM seguro_g30871276.registro_siniestro
WHERE nro_siniestro = 10 AND nro_contrato = 1;  -- fecha_respuesta debe ser NULL

UPDATE seguro_g30871276.registro_siniestro
   SET fecha_respuesta = '2026-07-20', id_rechazo = 'NO', monto_reconocido = 1150.00
 WHERE nro_siniestro = 10 AND nro_contrato = 1;

-- 2E) INSERT: el cliente demo evalua el producto al final de su experiencia
--    .Mueve el Indicador 4 para HCM Premium.
INSERT INTO seguro_g30871276.recomienda (cod_cliente, cod_evaluacion_servicio, cod_producto, recomienda_amigo)
VALUES (26, 2, 2, 'NO');


--  PASO 3 - Sincronizacion: correr el ETL manualmente
CALL seguro_dw_g30871276.sp_ejecutar_etl();


--  PASO 4 - Validacion "DESPUES"

-- 4.1) El cliente demo ya aparece en DIM_CLIENTE
SELECT * FROM seguro_dw_g30871276.dim_cliente WHERE cod_cliente_nk = 26;  -- debe dar 1 fila

-- 4.2) El contrato demo aparece en el hecho.
SELECT dc.nb_cliente, dk.nro_contrato_nk, dp.nb_producto, su.nb_sucursal,
       ec.descrip_estado, f.sk_dim_tiempo_fecha_inicio AS fecha_inicio_aaaammdd,
       f.sk_dim_tiempo_fecha_fin AS fecha_fin_aaaammdd, f.monto, f.cantidad
FROM seguro_dw_g30871276.fact_registro_contrato f
JOIN seguro_dw_g30871276.dim_cliente dc ON dc.sk_dim_cliente = f.sk_dim_cliente
JOIN seguro_dw_g30871276.dim_contrato dk ON dk.sk_dim_contrato = f.sk_dim_contrato
JOIN seguro_dw_g30871276.dim_producto dp ON dp.sk_dim_producto = f.sk_dim_producto
JOIN seguro_dw_g30871276.dim_sucursal su ON su.sk_dim_sucursal = f.sk_dim_sucursal
JOIN seguro_dw_g30871276.dim_estado_contrato ec ON ec.sk_dim_estado_contrato = f.sk_dim_estado_contrato
WHERE dc.cod_cliente_nk = 26;  -- debe devolver exactamente 1 fila

-- 4.3) El contrato 1 (Cliente 1, HCM Premium) sigue siendo UNA fila, pero
--      ahora con estado VENCIDO -> demuestra upsert (no duplico historico)
SELECT dk.nro_contrato_nk, dp.cod_producto_nk, dc.cod_cliente_nk, ec.descrip_estado
FROM seguro_dw_g30871276.fact_registro_contrato f
JOIN seguro_dw_g30871276.dim_contrato dk ON dk.sk_dim_contrato = f.sk_dim_contrato
JOIN seguro_dw_g30871276.dim_producto dp ON dp.sk_dim_producto = f.sk_dim_producto
JOIN seguro_dw_g30871276.dim_cliente  dc ON dc.sk_dim_cliente  = f.sk_dim_cliente
JOIN seguro_dw_g30871276.dim_estado_contrato ec ON ec.sk_dim_estado_contrato = f.sk_dim_estado_contrato
WHERE dk.nro_contrato_nk = 1 AND dp.cod_producto_nk = 2 AND dc.cod_cliente_nk = 1;
-- debe dar exactamente 1 fila, con descrip_estado = 'Vencido'





-- 4.4) Evidencia del PASO 2C: el siniestro nuevo (31) sobre la poliza demo
--      (61) aparece en el hecho, rechazado.
SELECT dsi.nro_siniestro_nk, dk.nro_contrato_nk, dc.nb_cliente, dp.nb_producto,
       ti_sin.fecha_completa AS fecha_siniestro, ti_resp.fecha_completa AS fecha_respuesta,
       f.id_rechazo, f.monto_reconocido, f.monto_solicitado
FROM seguro_dw_g30871276.fact_registro_siniestro f
JOIN seguro_dw_g30871276.dim_siniestro dsi ON dsi.sk_dim_siniestro = f.sk_dim_siniestro
JOIN seguro_dw_g30871276.dim_contrato dk ON dk.sk_dim_contrato = f.sk_dim_contrato
JOIN seguro_dw_g30871276.dim_cliente dc ON dc.sk_dim_cliente = f.sk_dim_cliente
JOIN seguro_dw_g30871276.dim_producto dp ON dp.sk_dim_producto = f.sk_dim_producto
JOIN seguro_dw_g30871276.dim_tiempo ti_sin ON ti_sin.sk_dim_tiempo = f.sk_fecha_siniestro
LEFT JOIN seguro_dw_g30871276.dim_tiempo ti_resp ON ti_resp.sk_dim_tiempo = f.sk_fecha_respuesta
WHERE dsi.nro_siniestro_nk = 31;  -- debe devolver exactamente 1 fila

-- 4.5) Evidencia del PASO 2D: el siniestro 10 (Cliente 1) sigue siendo UNA
--      fila, pero ahora con fecha_respuesta resuelta (ya no NULL)
SELECT dsi.nro_siniestro_nk, dk.nro_contrato_nk,
       ti_sin.fecha_completa AS fecha_siniestro, ti_resp.fecha_completa AS fecha_respuesta,
       f.id_rechazo, f.monto_reconocido
FROM seguro_dw_g30871276.fact_registro_siniestro f
JOIN seguro_dw_g30871276.dim_siniestro dsi ON dsi.sk_dim_siniestro = f.sk_dim_siniestro
JOIN seguro_dw_g30871276.dim_contrato dk ON dk.sk_dim_contrato = f.sk_dim_contrato
JOIN seguro_dw_g30871276.dim_tiempo ti_sin ON ti_sin.sk_dim_tiempo = f.sk_fecha_siniestro
LEFT JOIN seguro_dw_g30871276.dim_tiempo ti_resp ON ti_resp.sk_dim_tiempo = f.sk_fecha_respuesta
WHERE dsi.nro_siniestro_nk = 10 AND dk.nro_contrato_nk = 1;
-- debe devolver 1 fila; fecha_respuesta ya no debe ser NULL

-- 4.6) Evidencia del PASO 2E: la evaluacion nueva del cliente demo aparece
--      en el hecho, resuelta contra DIM_EVALUACION_SERVICIO
SELECT dc.nb_cliente, dp.nb_producto, de.cod_evaluacion_nk, de.nb_descrip, f.recomienda_amigo
FROM seguro_dw_g30871276.fact_evaluacion_servicio f
JOIN seguro_dw_g30871276.dim_cliente dc ON dc.sk_dim_cliente = f.sk_dim_cliente
JOIN seguro_dw_g30871276.dim_producto dp ON dp.sk_dim_producto = f.sk_dim_producto
JOIN seguro_dw_g30871276.dim_evaluacion_servicio de ON de.sk_dim_evaluacion = f.sk_dim_evaluacion_servicio
WHERE dc.cod_cliente_nk = 26;  -- debe devolver exactamente 1 fila


--  PASO 5 (COMENTADO) - Rollback para poder ensayar este script de nuevo
--    Descomentar y correr esto DESPUES de un ensayo si se quiere dejar la
--    fuente y el DW exactamente como estaban antes del PASO 1.
--    Borrar el cliente 26 o cualquier ajuste de la fuente y volver a
--    correr el ETL NO borra los cambios, hay que
--    borrarlas a mano en el DW tambien si se quiere un reset 100% limpio.
-- -- 5.1) Revertir la fuente transaccional
-- DELETE FROM seguro_g30871276.recomienda WHERE cod_cliente = 26 AND cod_producto = 2;
-- DELETE FROM seguro_g30871276.registro_siniestro WHERE nro_siniestro = 31 AND nro_contrato = 61;
-- DELETE FROM seguro_g30871276.siniestro WHERE nro_siniestro = 31;
-- UPDATE seguro_g30871276.registro_siniestro
--    SET fecha_respuesta = NULL, id_rechazo = 'NO', monto_reconocido = NULL
--  WHERE nro_siniestro = 10 AND nro_contrato = 1;
-- DELETE FROM seguro_g30871276.registro_contrato WHERE nro_contrato = 61;
-- DELETE FROM seguro_g30871276.contrato WHERE nro_contrato = 61;
-- UPDATE seguro_g30871276.registro_contrato
--    SET estado_contrato = 'ACTIVO'
--  WHERE nro_contrato = 1 AND cod_producto = 2 AND cod_cliente = 1;
-- DELETE FROM seguro_g30871276.cliente WHERE cod_cliente = 26;
--
-- -- 5.2) Revertir el DW a mano (el ETL no lo hace solo)
-- DELETE FROM seguro_dw_g30871276.fact_evaluacion_servicio f
-- USING seguro_dw_g30871276.dim_cliente dc
-- WHERE f.sk_dim_cliente = dc.sk_dim_cliente AND dc.cod_cliente_nk = 26;
-- DELETE FROM seguro_dw_g30871276.fact_registro_siniestro f
-- USING seguro_dw_g30871276.dim_siniestro dsi
-- WHERE f.sk_dim_siniestro = dsi.sk_dim_siniestro AND dsi.nro_siniestro_nk = 31;
-- DELETE FROM seguro_dw_g30871276.dim_siniestro WHERE nro_siniestro_nk = 31;
-- DELETE FROM seguro_dw_g30871276.fact_registro_contrato f
-- USING seguro_dw_g30871276.dim_cliente dc
-- WHERE f.sk_dim_cliente = dc.sk_dim_cliente AND dc.cod_cliente_nk = 26;
-- DELETE FROM seguro_dw_g30871276.dim_cliente WHERE cod_cliente_nk = 26;
-- DELETE FROM seguro_dw_g30871276.dim_contrato WHERE nro_contrato_nk = 61;
--
-- -- 5.3) Volver a correr el ETL para que el UPDATE de estado (5.1) y el de
-- --      fecha_respuesta (siniestro 10) se reflejen tambien en el hecho
-- CALL seguro_dw_g30871276.sp_ejecutar_etl();
