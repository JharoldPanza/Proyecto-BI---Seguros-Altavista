-- 1. Insertar Países
INSERT INTO PAIS (cod_pais, nb_pais) VALUES 
(1, 'Venezuela'),
(2, 'Colombia'),
(3, 'Panamá'),
(4, 'España');

-- 2. Insertar Ciudades
INSERT INTO CIUDAD (cod_ciudad, nb_ciudad, cod_pais) VALUES 
(1, 'Caracas', 1),
(2, 'Valencia', 1),
(3, 'Maracaibo', 1),
(4, 'Bogotá', 2),
(5, 'Medellín', 2),
(6, 'Ciudad de Panamá', 3),
(7, 'Madrid', 4);

-- 3. Insertar Sucursales
INSERT INTO SUCURSAL (cod_sucursal, nb_sucursal, cod_ciudad) VALUES 
(1, 'Sucursal Alta Vista Caracas', 1),
(2, 'Sucursal El Rosal', 1),
(3, 'Sucursal Viña', 2),
(4, 'Sucursal Lago', 3),
(5, 'Sucursal Centro Bogotá', 4),
(6, 'Sucursal El Poblado', 5),
(7, 'Sucursal Obarrio', 6),
(8, 'Sucursal Gran Vía', 7);

-- 4. Insertar Tipos de Producto
INSERT INTO TIPO_PRODUCTO (cod_tipo_producto, nb_tipo_producto) VALUES 
(1, 'PRESTACIÓN DE SERVICIOS'),
(2, 'PERSONALES'),
(3, 'DAÑOS'),
(4, 'PATRIMONIALES');

-- 5. Insertar Productos
INSERT INTO PRODUCTO (cod_producto, nb_producto, descripcion, calificacion, cod_tipo_producto) VALUES 
(1, 'HCM Básico', 'Cobertura médica esencial', 3.5, 2),
(2, 'HCM Premium', 'Cobertura médica amplia nacional e internacional', 4.8, 2),
(3, 'Auto Total', 'Cobertura amplia para vehículos', 4.2, 3),
(4, 'Auto RC', 'Responsabilidad Civil para vehículos', 3.0, 3),
(5, 'Hogar Seguro', 'Protección contra incendio, robo y sismo', 4.5, 4),
(6, 'Empresa Protegida', 'Póliza integral para pymes', 4.0, 4),
(7, 'Asistencia Vial Plus', 'Servicio de grúa y emergencias 24/7', 4.9, 1),
(8, 'Vida Plena', 'Seguro de vida temporal a 10 años', 4.1, 2),
(9, 'Odontología Express', 'Servicios odontológicos de emergencia', 3.2, 1),
(10, 'Viajero Frecuente', 'Seguro de viajes y pérdida de equipaje', 4.6, 2);

-- 6. Insertar Clientes
INSERT INTO CLIENTE (cod_cliente, nb_cliente, ci_rif, telefono, direccion, sexo, email, cod_sucursal) VALUES 
(1, 'Juan Pérez', 'V-12345678', '0414-1112233', 'Av. Principal, Caracas', 'M', 'juan.perez@email.com', 1),
(2, 'María Gómez', 'V-6210962', '0412-2223344', 'Urb. El Bosque, Valencia', 'F', 'maria.gomez@email.com', 3),
(3, 'Inversiones XYZ', 'J-30001111-9', '0212-3334455', 'Torre Empresarial, Caracas', 'M', 'contacto@xyz.com', 2),
(4, 'Ana Martínez', 'V-22333444', '0424-4445566', 'Calle 72, Maracaibo', 'F', 'ana.martinez@email.com', 4),
(5, 'Luis Rodríguez', 'E-8444555', '300-5556677', 'Cra 7, Bogotá', 'M', 'luis.rod@email.co', 5),
(6, 'Sofía Castro', 'V-19888777', '0416-6667788', 'Av. Bolívar, Valencia', 'F', 'sofia.castro@email.com', 3),
(7, 'Carlos Mendoza', 'V-15666777', '0414-7778899', 'Urb. La Castellana, Caracas', 'M', 'carlos.mendoza@email.com', 2),
(8, 'Constructora Andina', 'J-40002222-1', '301-8889900', 'El Poblado, Medellín', 'F', 'gerencia@candina.co', 6),
(9, 'Elena Ríos', 'PE-999888', '600-9990011', 'San Francisco, Panamá', 'F', 'elena.rios@email.pa', 7),
(10, 'Miguel Torres', 'V-10222333', '0424-0001122', 'La Candelaria, Caracas', 'M', 'miguel.torres@email.com', 1);

-- 7. Insertar Evaluaciones de Servicio (Restricción estricta del 1 al 5)
INSERT INTO EVALUACION_SERVICIO (cod_evaluacion_servicio, nb_descripcion) VALUES 
(1, 'MALO'),
(2, 'REGULAR'),
(3, 'BUENO'),
(4, 'MUY BUENO'),
(5, 'EXCELENTE');

-- 8. Insertar Recomendaciones (RECOMIENDA)
INSERT INTO RECOMIENDA (cod_cliente, cod_evaluacion_servicio, cod_producto, recomienda_amigo) VALUES 
(1, 4, 2, 'SI'),
(2, 5, 3, 'SI'),
(3, 2, 6, 'NO'),
(4, 3, 1, 'SI'),
(5, 5, 7, 'SI'),
(6, 1, 4, 'NO'),
(7, 4, 5, 'SI'),
(8, 3, 6, 'SI'),
(9, 5, 10, 'SI'),
(10, 2, 9, 'NO');

-- 9. Insertar Contratos
INSERT INTO CONTRATO (nro_contrato, descrip_contrato) VALUES 
(1, 'Póliza de Salud Familiar 2024'),
(2, 'Seguro de Vehículo - Toyota Corolla'),
(3, 'Póliza Colectiva Pymes 2023'),
(4, 'Seguro de Vida - Directivos'),
(5, 'Asistencia Grúa - Flota Taxis'),
(6, 'Póliza Hogar - Apartamento Maracaibo'),
(7, 'Póliza Salud Básica 2024'),
(8, 'Seguro Viajero - Gira Europea'),
(9, 'Seguro Vehículo - Ford Explorer'),
(10, 'Póliza Odontológica Empresarial');

-- 10. Insertar Registro de Contratos
INSERT INTO REGISTRO_CONTRATO (nro_contrato, cod_producto, cod_cliente, fecha_inicio, fecha_fin, monto, estado_contrato) VALUES 
(1, 2, 1, '2024-01-01', '2024-12-31', 1200.00, 'ACTIVO'),
(2, 3, 2, '2023-06-15', '2024-06-15', 450.00, 'ACTIVO'),
(3, 6, 3, '2023-02-10', '2024-02-10', 2500.00, 'VENCIDO'),
(4, 8, 7, '2024-03-01', '2025-03-01', 800.00, 'ACTIVO'),
(5, 7, 5, '2023-11-20', '2024-11-20', 150.00, 'ACTIVO'),
(6, 5, 4, '2022-05-10', '2023-05-10', 300.00, 'VENCIDO'),
(7, 1, 6, '2024-04-01', '2024-10-01', 200.00, 'SUSPENDIDO'),
(8, 10, 9, '2024-05-15', '2024-06-15', 120.00, 'ACTIVO'),
(9, 4, 10, '2023-08-01', '2024-08-01', 180.00, 'ACTIVO'),
(10, 9, 8, '2024-01-15', '2024-12-31', 600.00, 'ACTIVO');

-- 11. Insertar Siniestros
INSERT INTO SINIESTRO (nro_siniestro, descripcion_siniestro) VALUES 
(1, 'Choque frontal con daños moderados'),
(2, 'Hospitalización por Apendicitis'),
(3, 'Robo de vivienda'),
(4, 'Falla de batería en autopista'),
(5, 'Filtración de tubería principal'),
(6, 'Pérdida de equipaje en vuelo internacional'),
(7, 'Emergencia odontológica - Extracción'),
(8, 'Colisión leve en estacionamiento'),
(9, 'Incendio parcial en local comercial'),
(10, 'Gastos médicos por accidente de tránsito');

-- 12. Insertar Registro de Siniestros
INSERT INTO REGISTRO_SINIESTRO (nro_siniestro, nro_contrato, fecha_siniestro, fecha_respuesta, id_rechazo, monto_reconocido, monto_solicitado) VALUES 
(1, 2, '2023-09-10', '2023-09-15', 'NO', 800.00, 850.00),
(2, 1, '2024-02-05', '2024-02-12', 'NO', 2500.00, 2500.00),
(3, 6, '2022-12-24', '2023-01-10', 'SI', 0.00, 5000.00), -- Siniestro rechazado
(4, 5, '2024-01-08', '2024-01-08', 'NO', 50.00, 50.00),
(5, 6, '2023-03-15', '2023-03-20', 'NO', 1200.00, 1500.00),
(6, 8, '2024-05-20', '2024-05-25', 'NO', 400.00, 400.00),
(7, 10, '2024-03-10', '2024-03-11', 'NO', 80.00, 100.00),
(8, 9, '2024-01-15', '2024-02-01', 'SI', 0.00, 300.00), -- Siniestro rechazado
(9, 3, '2023-11-05', '2023-11-30', 'NO', 15000.00, 18000.00),
(10, 1, '2024-04-18', NULL, 'NO', NULL, 1200.00); -- Siniestro en proceso (sin fecha de respuesta aún)

-- Actualizar secuencia de la tabla PAIS
SELECT setval('pais_cod_pais_seq', (SELECT MAX(cod_pais) FROM PAIS));

-- Actualizar secuencia de la tabla CIUDAD
SELECT setval('ciudad_cod_ciudad_seq', (SELECT MAX(cod_ciudad) FROM CIUDAD));

-- Actualizar secuencia de la tabla SUCURSAL
SELECT setval('sucursal_cod_sucursal_seq', (SELECT MAX(cod_sucursal) FROM SUCURSAL));

-- Actualizar secuencia de la tabla TIPO_PRODUCTO
SELECT setval('tipo_producto_cod_tipo_producto_seq', (SELECT MAX(cod_tipo_producto) FROM TIPO_PRODUCTO));

-- Actualizar secuencia de la tabla PRODUCTO
SELECT setval('producto_cod_producto_seq', (SELECT MAX(cod_producto) FROM PRODUCTO));

-- Actualizar secuencia de la tabla CLIENTE
SELECT setval('cliente_cod_cliente_seq', (SELECT MAX(cod_cliente) FROM CLIENTE));

-- Actualizar secuencia de la tabla CONTRATO
SELECT setval('contrato_nro_contrato_seq', (SELECT MAX(nro_contrato) FROM CONTRATO));

-- Actualizar secuencia de la tabla SINIESTRO
SELECT setval('siniestro_nro_siniestro_seq', (SELECT MAX(nro_siniestro) FROM SINIESTRO));