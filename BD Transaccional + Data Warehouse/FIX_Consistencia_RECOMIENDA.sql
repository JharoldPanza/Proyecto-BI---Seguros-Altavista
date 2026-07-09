-- ============================================================================
-- CORRECCION DE CONSISTENCIA - Tabla RECOMIENDA (esquema fuente)
-- ----------------------------------------------------------------------------
-- Regla de negocio (enunciado Fase I): el asegurado evalua el Producto
-- "a la finalizacion del tiempo del seguro", es decir, solo puede evaluar
-- productos que contrato. En los datos de prueba originales, 5 de las 10
-- evaluaciones referian a pares (cliente, producto) sin contrato en
-- REGISTRO_CONTRATO. Este script reasigna cada evaluacion al producto que
-- ese mismo cliente si contrato, preservando la calificacion y la respuesta
-- de "recomienda a un amigo".
-- Ejecutar UNA vez sobre el esquema fuente, antes del ETL.
-- ============================================================================
SET search_path TO seguro_g30871276;

UPDATE recomienda SET cod_producto = 5 WHERE cod_cliente = 4  AND cod_producto = 1;
UPDATE recomienda SET cod_producto = 1 WHERE cod_cliente = 6  AND cod_producto = 4;
UPDATE recomienda SET cod_producto = 8 WHERE cod_cliente = 7  AND cod_producto = 5;
UPDATE recomienda SET cod_producto = 9 WHERE cod_cliente = 8  AND cod_producto = 6;
UPDATE recomienda SET cod_producto = 4 WHERE cod_cliente = 10 AND cod_producto = 9;

-- Verificacion: debe devolver 0
SELECT COUNT(*) AS evaluaciones_huerfanas
FROM recomienda r
WHERE NOT EXISTS (SELECT 1 FROM registro_contrato rc
                  WHERE rc.cod_cliente = r.cod_cliente
                    AND rc.cod_producto = r.cod_producto);
