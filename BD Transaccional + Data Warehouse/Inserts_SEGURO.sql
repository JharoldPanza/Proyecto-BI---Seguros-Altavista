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

-- 7. Insertar Evaluaciones de Servicio 
INSERT INTO EVALUACION_SERVICIO (cod_evaluacion_servicio, nb_descripcion) VALUES 
(1, 'MALO'),
(2, 'REGULAR'),
(3, 'BUENO'),
(4, 'MUY BUENO'),
(5, 'EXCELENTE');

-- 8. Insertar Recomendaciones 
INSERT INTO RECOMIENDA (cod_cliente, cod_evaluacion_servicio, cod_producto, recomienda_amigo) VALUES 
(1, 4, 2, 'SI'),
(2, 5, 3, 'SI'),
(3, 2, 6, 'NO'),
(4, 3, 5, 'SI'),
(5, 5, 7, 'SI'),
(6, 1, 1, 'NO'),
(7, 4, 8, 'SI'),
(8, 3, 9, 'SI'),
(9, 5, 10, 'SI'),
(10, 2, 4, 'NO');

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


-- 6b. Insertar Clientes adicionales 
INSERT INTO CLIENTE (cod_cliente, nb_cliente, ci_rif, telefono, direccion, sexo, email, cod_sucursal) VALUES
(11, 'Pedro Alvarez 11', 'V-10001903', '0414-1000407', 'Direccion Demo 11, Caracas', 'M', 'cliente11@email.com', 1),
(12, 'Daniela Reyes 12', 'V-10002076', '0414-1000444', 'Direccion Demo 12, Caracas', 'F', 'cliente12@email.com', 1),
(13, 'Diego Fernandez 13', 'V-10002249', '0412-1000481', 'Direccion Demo 13, Caracas', 'M', 'cliente13@email.com', 2),
(14, 'Ricardo Nunez 14', 'V-10002422', '0412-1000518', 'Direccion Demo 14, Caracas', 'M', 'cliente14@email.com', 2),
(15, 'Valentina Cruz 15', 'V-10002595', '0424-1000555', 'Direccion Demo 15, Valencia', 'F', 'cliente15@email.com', 3),
(16, 'Comercial Delta 16', 'J-40003016-8', '0424-1000592', 'Direccion Demo 16, Valencia', 'M', 'contacto16@empresa16.com', 3),
(17, 'Andres Silva 17', 'V-10002941', '0416-1000629', 'Direccion Demo 17, Maracaibo', 'M', 'cliente17@email.com', 4),
(18, 'Andres Silva 18', 'V-10003114', '0416-1000666', 'Direccion Demo 18, Maracaibo', 'M', 'cliente18@email.com', 4),
(19, 'Daniela Reyes 19', 'E-8002603', '301-4001007', 'Direccion Demo 19, Bogota', 'F', 'cliente19@email.com', 5),
(20, 'Paula Jimenez 20', 'E-8002740', '300-4001060', 'Direccion Demo 20, Medellin', 'F', 'cliente20@email.com', 6),
(21, 'Diego Fernandez 21', 'PE-904431', '630-1001281', 'Direccion Demo 21, Panama', 'M', 'cliente21@email.com', 7),
(22, 'Grupo Rivas 22', 'J-40003022-5', '+34-622-101562', 'Direccion Demo 22, Madrid', 'F', 'contacto22@empresa22.com', 8),
(23, 'Camila Herrera 23', 'ES-40007613', '+34-623-101633', 'Direccion Demo 23, Madrid', 'F', 'cliente23@email.com', 8),
(24, 'Manuel Vargas 24', 'ES-40007944', '+34-624-101704', 'Direccion Demo 24, Madrid', 'M', 'cliente24@email.com', 8),
(25, 'Ricardo Nunez 25', 'ES-40008275', '+34-625-101775', 'Direccion Demo 25, Madrid', 'M', 'cliente25@email.com', 8);

-- 8b. Insertar Recomendaciones adicionales
INSERT INTO RECOMIENDA (cod_cliente, cod_evaluacion_servicio, cod_producto, recomienda_amigo) VALUES
(18, 2, 1, 'NO'),
(3, 4, 1, 'SI'),
(11, 4, 2, 'SI'),
(3, 3, 2, 'SI'),
(14, 5, 2, 'SI'),
(1, 5, 3, 'SI'),
(23, 4, 3, 'SI'),
(25, 4, 4, 'NO'),
(12, 5, 4, 'SI'),
(24, 5, 5, 'SI'),
(18, 3, 5, 'SI'),
(20, 4, 5, 'SI'),
(13, 5, 6, 'SI'),
(1, 5, 7, 'SI'),
(18, 4, 7, 'SI'),
(20, 4, 7, 'NO'),
(2, 3, 8, 'SI'),
(6, 4, 8, 'SI'),
(13, 3, 9, 'NO'),
(16, 1, 10, 'NO'),
(3, 5, 10, 'SI'),
(14, 4, 10, 'SI'),
(21, 2, 1, 'SI'),  
(7, 4, 1, 'SI'),  
(19, 3, 4, 'NO');  

-- 9b. Insertar Contratos adicionales
INSERT INTO CONTRATO (nro_contrato, descrip_contrato) VALUES
(11, 'Poliza HCM Basico - Cliente 23'),
(12, 'Poliza Auto Total - Cliente 15'),
(13, 'Poliza HCM Premium - Cliente 14'),
(14, 'Poliza Vida Plena - Cliente 19'),
(15, 'Poliza HCM Premium - Cliente 6'),
(16, 'Poliza Asistencia Vial Plus - Cliente 18'),
(17, 'Poliza Auto RC - Cliente 3'),
(18, 'Poliza Hogar Seguro - Cliente 12'),
(19, 'Poliza Hogar Seguro - Cliente 10'),
(20, 'Poliza HCM Premium - Cliente 5'),
(21, 'Poliza HCM Basico - Cliente 6'),
(22, 'Poliza Auto Total - Cliente 20'),
(23, 'Poliza Vida Plena - Cliente 14'),
(24, 'Poliza Asistencia Vial Plus - Cliente 25'),
(25, 'Poliza Hogar Seguro - Cliente 13'),
(26, 'Poliza Odontologia Express - Cliente 24'),
(27, 'Poliza Hogar Seguro - Cliente 21'),
(28, 'Poliza Vida Plena - Cliente 9'),
(29, 'Poliza HCM Basico - Cliente 18'),
(30, 'Poliza Empresa Protegida - Cliente 7'),
(31, 'Poliza HCM Basico - Cliente 10'),
(32, 'Poliza HCM Premium - Cliente 24'),
(33, 'Poliza Auto RC - Cliente 9'),
(34, 'Poliza Empresa Protegida - Cliente 24'),
(35, 'Poliza Hogar Seguro - Cliente 17'),
(36, 'Poliza HCM Premium - Cliente 16'),
(37, 'Poliza Auto RC - Cliente 11'),
(38, 'Poliza Asistencia Vial Plus - Cliente 25'),
(39, 'Poliza HCM Basico - Cliente 12'),
(40, 'Poliza Viajero Frecuente - Cliente 3'),
(41, 'Poliza Asistencia Vial Plus - Cliente 13'),
(42, 'Poliza HCM Premium - Cliente 4'),
(43, 'Poliza Asistencia Vial Plus - Cliente 23'),
(44, 'Poliza Auto Total - Cliente 1'),
(45, 'Poliza Viajero Frecuente - Cliente 20'),
(46, 'Poliza Empresa Protegida - Cliente 7'),
(47, 'Poliza HCM Premium - Cliente 4'),
(48, 'Poliza Hogar Seguro - Cliente 2'),
(49, 'Poliza Auto Total - Cliente 22'),
(50, 'Poliza Odontologia Express - Cliente 5'),
(51, 'Poliza Auto RC - Cliente 15'),
(52, 'Poliza Vida Plena - Cliente 16'),
(53, 'Poliza Auto Total - Cliente 8'),
(54, 'Poliza Asistencia Vial Plus - Cliente 23'),
(55, 'Poliza Viajero Frecuente - Cliente 17'),
(56, 'Poliza HCM Premium - Cliente 23'),
(57, 'Poliza Odontologia Express - Cliente 15'),
(58, 'Poliza Vida Plena - Cliente 14'),
(59, 'Poliza HCM Basico - Cliente 19'),
(60, 'Poliza Asistencia Vial Plus - Cliente 6');

-- 10b. Insertar Registro de Contratos adicionales
INSERT INTO REGISTRO_CONTRATO (nro_contrato, cod_producto, cod_cliente, fecha_inicio, fecha_fin, monto, estado_contrato) VALUES
(11, 1, 23, '2026-11-21', '2027-05-21', 452.73, 'VENCIDO'),
(12, 3, 15, '2022-12-11', '2023-06-11', 831.41, 'ACTIVO'),
(13, 2, 14, '2025-04-18', '2026-04-18', 1239.25, 'VENCIDO'),
(14, 8, 19, '2025-03-09', '2026-03-09', 878.58, 'ACTIVO'),
(15, 2, 6, '2024-02-15', '2026-02-15', 1182.18, 'ACTIVO'),
(16, 7, 18, '2024-11-18', '2025-05-18', 282.98, 'ACTIVO'),
(17, 4, 3, '2026-04-06', '2027-04-06', 454.83, 'SUSPENDIDO'),
(18, 5, 12, '2024-04-28', '2025-04-28', 1663.42, 'SUSPENDIDO'),
(19, 5, 10, '2023-03-13', '2023-09-13', 1745.46, 'ACTIVO'),
(20, 2, 5, '2024-05-26', '2025-05-26', 1435.09, 'VENCIDO'),
(21, 1, 6, '2026-12-24', '2028-12-24', 777.41, 'ACTIVO'),
(22, 3, 20, '2022-08-05', '2023-08-05', 870.33, 'ACTIVO'),
(23, 8, 14, '2023-01-19', '2025-01-19', 717.12, 'ACTIVO'),
(24, 7, 25, '2023-06-02', '2023-12-02', 220.64, 'ACTIVO'),
(25, 5, 13, '2024-09-28', '2026-09-28', 925.86, 'ACTIVO'),
(26, 9, 24, '2025-09-03', '2026-09-03', 114.25, 'SUSPENDIDO'),
(27, 5, 21, '2026-02-22', '2027-02-22', 1169.74, 'ACTIVO'),
(28, 8, 9, '2025-10-08', '2027-10-08', 1173.31, 'VENCIDO'),
(29, 1, 18, '2024-10-03', '2025-10-03', 774.98, 'VENCIDO'),
(30, 6, 7, '2026-10-17', '2027-10-17', 4315.46, 'VENCIDO'),
(31, 1, 10, '2023-04-22', '2024-04-22', 548.89, 'ACTIVO'),
(32, 2, 24, '2024-07-05', '2025-07-05', 1667.25, 'ACTIVO'),
(33, 4, 9, '2025-02-01', '2026-02-01', 503.62, 'ACTIVO'),
(34, 6, 24, '2023-10-04', '2024-04-04', 3314.84, 'VENCIDO'),
(35, 5, 17, '2025-09-09', '2026-09-09', 1693.93, 'ACTIVO'),
(36, 2, 16, '2022-02-08', '2023-02-08', 1434.73, 'VENCIDO'),
(37, 4, 11, '2025-08-27', '2027-08-27', 533.27, 'VENCIDO'),
(38, 7, 25, '2024-10-26', '2026-10-26', 127.27, 'ACTIVO'),
(39, 1, 12, '2025-09-10', '2026-03-10', 927.02, 'SUSPENDIDO'),
(40, 10, 3, '2023-03-09', '2023-09-09', 1050.52, 'ACTIVO'),
(41, 7, 13, '2025-12-18', '2026-12-18', 170.12, 'ACTIVO'),
(42, 2, 4, '2023-10-07', '2024-10-07', 1324.86, 'ACTIVO'),
(43, 7, 23, '2026-11-28', '2027-11-28', 207.88, 'ACTIVO'),
(44, 3, 1, '2022-05-28', '2022-11-28', 704.76, 'ACTIVO'),
(45, 10, 20, '2023-07-27', '2024-07-27', 517.77, 'VENCIDO'),
(46, 6, 7, '2024-06-25', '2025-06-25', 3565.53, 'SUSPENDIDO'),
(47, 2, 4, '2024-05-06', '2025-05-06', 1794.77, 'VENCIDO'),
(48, 5, 2, '2025-07-18', '2026-01-18', 880.76, 'VENCIDO'),
(49, 3, 22, '2022-12-05', '2024-12-05', 659.18, 'SUSPENDIDO'),
(50, 9, 5, '2026-06-19', '2028-06-19', 124.99, 'VENCIDO'),
(51, 4, 15, '2022-03-02', '2023-03-02', 411.27, 'ACTIVO'),
(52, 8, 16, '2025-01-12', '2026-01-12', 1248.17, 'ACTIVO'),
(53, 3, 8, '2024-11-04', '2025-11-04', 1261.89, 'ACTIVO'),
(54, 7, 23, '2022-07-20', '2023-07-20', 275.97, 'ACTIVO'),
(55, 10, 17, '2023-04-28', '2024-04-28', 1105.01, 'SUSPENDIDO'),
(56, 2, 23, '2025-03-14', '2025-09-14', 1292.14, 'ACTIVO'),
(57, 9, 15, '2026-06-26', '2027-06-26', 213.30, 'ACTIVO'),
(58, 8, 14, '2024-12-26', '2025-12-26', 893.12, 'ACTIVO'),
(59, 1, 19, '2022-12-04', '2023-12-04', 890.97, 'ACTIVO'),
(60, 7, 6, '2024-08-08', '2025-08-08', 258.29, 'SUSPENDIDO');

-- 11b. Insertar Siniestros adicionales
INSERT INTO SINIESTRO (nro_siniestro, descripcion_siniestro) VALUES
(11, 'Choque leve en avenida principal'),
(12, 'Robo de accesorios del vehiculo'),
(13, 'Fuga de agua en cocina'),
(14, 'Rotura de vidrio por granizo'),
(15, 'Consulta de emergencia dental'),
(16, 'Extravio de equipaje'),
(17, 'Hospitalizacion por gripe severa'),
(18, 'Danio por cortocircuito electrico'),
(19, 'Caida con fractura menor'),
(20, 'Incendio menor en deposito'),
(21, 'Colision multiple en autopista'),
(22, 'Robo con violencia en sucursal'),
(23, 'Filtracion en techo por lluvia'),
(24, 'Cirugia ambulatoria de urgencia'),
(25, 'Perdida de equipo electronico'),
(26, 'Choque por alcance en semaforo'),
(27, 'Rotura de tuberia principal'),
(28, 'Emergencia odontologica nocturna'),
(29, 'Asistencia por averia mecanica'),
(30, 'Cancelacion de vuelo internacional');

-- 12b. Insertar Registro de Siniestros adicionales
INSERT INTO REGISTRO_SINIESTRO (nro_siniestro, nro_contrato, fecha_siniestro, fecha_respuesta, id_rechazo, monto_reconocido, monto_solicitado) VALUES
(11, 31, '2023-10-28', '2023-11-05', 'NO', 1765.81, 2007.30),
(12, 29, '2024-11-17', '2024-11-26', 'NO', 1466.99, 1567.46),
(13, 3, '2023-12-11', '2023-12-15', 'NO', 772.06, 842.75),
(14, 36, '2022-03-09', NULL, 'NO', NULL, 2207.35),
(15, 42, '2024-05-27', '2024-06-13', 'SI', 0.00, 2706.55),
(16, 22, '2022-12-23', NULL, 'NO', NULL, 1598.17),
(17, 53, '2025-02-22', '2025-02-25', 'NO', 2559.98, 2768.65),
(18, 17, '2026-09-16', '2026-09-30', 'NO', 1927.29, 2115.85),
(19, 33, '2025-09-14', '2025-09-27', 'NO', 2507.32, 2716.19),
(20, 25, '2025-05-03', '2025-05-04', 'NO', 664.00, 693.73),
(21, 35, '2026-03-02', '2026-03-17', 'NO', 1507.75, 1572.63),
(22, 34, '2023-11-26', '2023-12-16', 'NO', 2346.87, 2469.80),
(23, 43, '2027-04-02', '2027-04-07', 'SI', 0.00, 794.94),
(24, 1, '2024-05-18', '2024-06-06', 'SI', 0.00, 2113.35),
(25, 1, '2024-11-01', '2024-11-02', 'NO', 2533.10, 2592.49),
(26, 52, '2025-05-14', '2025-05-31', 'NO', 1679.43, 1707.62),
(27, 14, '2025-11-07', NULL, 'NO', NULL, 1630.91),
(28, 57, '2027-02-17', '2027-03-06', 'NO', 2425.71, 2728.02),
(29, 45, '2024-04-05', '2024-04-13', 'NO', 850.19, 889.75),
(30, 9, '2024-05-26', '2024-05-29', 'NO', 663.14, 764.72);

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