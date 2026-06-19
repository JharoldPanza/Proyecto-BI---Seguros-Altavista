
CREATE SCHEMA IF NOT EXISTS SEGURO_G30871276;
SET search_path TO SEGURO_G30871276;

-- Tabla PAIS
CREATE TABLE PAIS (
    cod_pais SERIAL PRIMARY KEY, 
    nb_pais VARCHAR(100) NOT NULL
);

-- Tabla CIUDAD
CREATE TABLE CIUDAD (
    cod_ciudad SERIAL PRIMARY KEY,
    nb_ciudad VARCHAR(100) NOT NULL,
    cod_pais INTEGER NOT NULL,
    CONSTRAINT fk_ciudad_pais FOREIGN KEY (cod_pais) REFERENCES PAIS(cod_pais)
);

-- Tabla SUCURSAL
CREATE TABLE SUCURSAL (
    cod_sucursal SERIAL PRIMARY KEY, 
    nb_sucursal VARCHAR(100) NOT NULL,
    cod_ciudad INTEGER NOT NULL,
    CONSTRAINT fk_sucursal_ciudad FOREIGN KEY (cod_ciudad) REFERENCES CIUDAD(cod_ciudad)
);

-- Tabla TIPO_PRODUCTO (TipoSeguro)
CREATE TABLE TIPO_PRODUCTO (
    cod_tipo_producto SERIAL PRIMARY KEY, 
    nb_tipo_producto VARCHAR(100) NOT NULL,
    CONSTRAINT chk_tipo_producto CHECK (
        UPPER(nb_tipo_producto) IN ('PRESTACIÓN DE SERVICIOS', 'PERSONALES', 'DAÑOS', 'PATRIMONIALES')
    )
);

-- Tabla PRODUCTO (Seguro)
CREATE TABLE PRODUCTO (
    cod_producto SERIAL PRIMARY KEY, 
    nb_producto VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255),
    calificacion NUMERIC(3,2),
    cod_tipo_producto INTEGER NOT NULL,
    CONSTRAINT chk_calificacion_prod CHECK (calificacion >= 1 AND calificacion <= 5),
    CONSTRAINT fk_producto_tipo FOREIGN KEY (cod_tipo_producto) REFERENCES TIPO_PRODUCTO(cod_tipo_producto)
);

-- Tabla CLIENTE
CREATE TABLE CLIENTE (
    cod_cliente SERIAL PRIMARY KEY, 
    nb_cliente VARCHAR(150) NOT NULL,
    ci_rif VARCHAR(20) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    direccion VARCHAR(255),
    sexo CHAR(1),
    email VARCHAR(100),
    cod_sucursal INTEGER NOT NULL,
    CONSTRAINT chk_sexo_cliente CHECK (UPPER(sexo) IN ('M', 'F')),
    CONSTRAINT fk_cliente_sucursal FOREIGN KEY (cod_sucursal) REFERENCES SUCURSAL(cod_sucursal)
);

-- Tabla EVALUACION_SERVICIO
CREATE TABLE EVALUACION_SERVICIO (
    cod_evaluacion_servicio INTEGER PRIMARY KEY,
    nb_descripcion VARCHAR(50) NOT NULL,
    CONSTRAINT chk_codigo_evaluacion CHECK (cod_evaluacion_servicio BETWEEN 1 AND 5),
    CONSTRAINT chk_evaluacion_exacta CHECK (
        (cod_evaluacion_servicio = 1 AND UPPER(nb_descripcion) = 'MALO') OR
        (cod_evaluacion_servicio = 2 AND UPPER(nb_descripcion) = 'REGULAR') OR
        (cod_evaluacion_servicio = 3 AND UPPER(nb_descripcion) = 'BUENO') OR
        (cod_evaluacion_servicio = 4 AND UPPER(nb_descripcion) = 'MUY BUENO') OR
        (cod_evaluacion_servicio = 5 AND UPPER(nb_descripcion) = 'EXCELENTE')
    )
);

-- Tabla CONTRATO
CREATE TABLE CONTRATO (
    nro_contrato SERIAL PRIMARY KEY, 
    descrip_contrato VARCHAR(255) NOT NULL
);

-- Tabla SINIESTRO
CREATE TABLE SINIESTRO (
    nro_siniestro SERIAL PRIMARY KEY, 
    descripcion_siniestro VARCHAR(255) NOT NULL
);


-- Tabla RECOMIENDA
CREATE TABLE RECOMIENDA (
    cod_cliente INTEGER NOT NULL,
    cod_evaluacion_servicio INTEGER NOT NULL,
    cod_producto INTEGER NOT NULL,
    recomienda_amigo VARCHAR(2), 
    PRIMARY KEY (cod_cliente, cod_producto, cod_evaluacion_servicio),
    CONSTRAINT fk_recomienda_cliente FOREIGN KEY (cod_cliente) REFERENCES CLIENTE(cod_cliente),
    CONSTRAINT fk_recomienda_evaluacion FOREIGN KEY (cod_evaluacion_servicio) REFERENCES EVALUACION_SERVICIO(cod_evaluacion_servicio),
    CONSTRAINT fk_recomienda_producto FOREIGN KEY (cod_producto) REFERENCES PRODUCTO(cod_producto),
    CONSTRAINT chk_recomienda_amigo CHECK (UPPER(recomienda_amigo) IN ('SI', 'NO'))
);

-- Tabla REGISTRO_CONTRATO
CREATE TABLE REGISTRO_CONTRATO (
    nro_contrato INTEGER NOT NULL,
    cod_producto INTEGER NOT NULL,
    cod_cliente INTEGER NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    monto NUMERIC(18,2) NOT NULL,
    estado_contrato VARCHAR(20) NOT NULL, 
    PRIMARY KEY (nro_contrato, cod_producto, cod_cliente),
    CONSTRAINT fk_registro_contrato FOREIGN KEY (nro_contrato) REFERENCES CONTRATO(nro_contrato),
    CONSTRAINT fk_registro_producto FOREIGN KEY (cod_producto) REFERENCES PRODUCTO(cod_producto),
    CONSTRAINT fk_registro_cliente FOREIGN KEY (cod_cliente) REFERENCES CLIENTE(cod_cliente),
    CONSTRAINT chk_estado_contrato CHECK (UPPER(estado_contrato) IN ('ACTIVO', 'VENCIDO', 'SUSPENDIDO')),
    CONSTRAINT chk_fechas_contrato CHECK (fecha_fin >= fecha_inicio)
);

-- Tabla REGISTRO_SINIESTRO
CREATE TABLE REGISTRO_SINIESTRO (
    nro_siniestro INTEGER NOT NULL,
    nro_contrato INTEGER NOT NULL,
    fecha_siniestro DATE NOT NULL,
    fecha_respuesta DATE,
    id_rechazo VARCHAR(2) NOT NULL, 
    monto_reconocido NUMERIC(18,2),
    monto_solicitado NUMERIC(18,2) NOT NULL,
    PRIMARY KEY (nro_siniestro, nro_contrato),
    CONSTRAINT fk_reg_siniestro_siniestro FOREIGN KEY (nro_siniestro) REFERENCES SINIESTRO(nro_siniestro),
    CONSTRAINT fk_reg_siniestro_contrato FOREIGN KEY (nro_contrato) REFERENCES CONTRATO(nro_contrato),
    CONSTRAINT chk_id_rechazo CHECK (UPPER(id_rechazo) IN ('SI', 'NO')),
    CONSTRAINT chk_fechas_siniestro CHECK (fecha_respuesta IS NULL OR fecha_respuesta >= fecha_siniestro)
);