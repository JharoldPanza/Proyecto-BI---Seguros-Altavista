--  Como usarlo el dia de la defensa:
--    1) Correr la seccion "PASO 0" y dejarla a la vista (captura del estado
--       "antes" de los 2 indicadores que se van a mover).
--    2) Correr "PASO 1" y "PASO 2" (la modificacion de la fuente).
--    3) Correr "PASO 3" (CALL al ETL) delante del jurado.
--    4) Correr "PASO 4" y mostrar que los mismos indicadores del PASO 0
--       cambiaron de forma coherente, y que los conteos de "no duplicados"
--       dan 1, no 2.
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





-- 4.4) Indicador 8 "otra vez" - comparar contra el PASO 0: Caracas (sucursal 1)
--      debe subir en +5000.00 respecto de la foto de "antes"
SELECT su.nb_sucursal, ROUND(SUM(f.monto), 2) AS monto_total
FROM seguro_dw_g30871276.fact_registro_contrato f
JOIN seguro_dw_g30871276.dim_sucursal su ON su.sk_dim_sucursal = f.sk_dim_sucursal
GROUP BY su.nb_sucursal
ORDER BY monto_total DESC;

-- 4.5) Indicador 2 "otra vez" - comparar contra el PASO 0: ACTIVO -1, VENCIDO +1
SELECT ec.descrip_estado, COUNT(*) AS cantidad_contratos
FROM seguro_dw_g30871276.fact_registro_contrato f
JOIN seguro_dw_g30871276.dim_estado_contrato ec ON ec.sk_dim_estado_contrato = f.sk_dim_estado_contrato
GROUP BY ec.descrip_estado
ORDER BY cantidad_contratos DESC;


--  PASO 5 (COMENTADO) - Rollback para poder ensayar este script de nuevo
--    Descomentar y correr esto DESPUES de un ensayo si se quiere dejar la
--    fuente y el DW exactamente como estaban antes del PASO 1.
--    OJO: como las dimensiones son SCD1 sin synchronize (a proposito, ver
--    conversacion de diseno), borrar el cliente 26 de la fuente y volver a
--    correr el ETL NO borra su fila en DIM_CLIENTE ni en el hecho -> hay que
--    borrarlas a mano en el DW tambien si se quiere un reset 100% limpio.
-- -- 5.1) Revertir la fuente transaccional
-- DELETE FROM seguro_g30871276.registro_contrato WHERE nro_contrato = 61;
-- DELETE FROM seguro_g30871276.contrato WHERE nro_contrato = 61;
-- UPDATE seguro_g30871276.registro_contrato
--    SET estado_contrato = 'ACTIVO'
--  WHERE nro_contrato = 1 AND cod_producto = 2 AND cod_cliente = 1;
-- DELETE FROM seguro_g30871276.cliente WHERE cod_cliente = 26;
--
-- -- 5.2) Revertir el DW a mano (el ETL no lo hace solo, ver nota arriba)
-- DELETE FROM seguro_dw_g30871276.fact_registro_contrato f
-- USING seguro_dw_g30871276.dim_cliente dc
-- WHERE f.sk_dim_cliente = dc.sk_dim_cliente AND dc.cod_cliente_nk = 26;
-- DELETE FROM seguro_dw_g30871276.dim_cliente WHERE cod_cliente_nk = 26;
-- DELETE FROM seguro_dw_g30871276.dim_contrato WHERE nro_contrato_nk = 61;
--
-- -- 5.3) Volver a correr el ETL para que el UPDATE de estado (5.1) se
-- --      refleje tambien en el hecho
-- CALL seguro_dw_g30871276.sp_ejecutar_etl();
