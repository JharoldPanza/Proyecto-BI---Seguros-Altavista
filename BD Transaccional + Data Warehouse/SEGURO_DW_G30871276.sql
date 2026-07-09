
-- CONFIGURACIÓN DEL ESQUEMA
CREATE SCHEMA IF NOT EXISTS SEGURO_DW_G30871276;
SET search_path TO SEGURO_DW_G30871276;

-- 1. CREACIÓN DE DIMENSIONES

CREATE TABLE DIM_TIEMPO (
    sk_dim_tiempo INTEGER PRIMARY KEY,
    cod_annio INTEGER NOT NULL,
    cod_mes INTEGER NOT NULL,
    cod_dia_annio INTEGER,
    cod_dia_mes INTEGER NOT NULL,
    cod_dia_semana INTEGER,
    cod_semana INTEGER,
    desc_dia_semana VARCHAR(20),
    desc_dia_semana_corta VARCHAR(5),
    desc_mes VARCHAR(20),
    desc_mes_corta VARCHAR(3),
    desc_trimestre VARCHAR(10), 
    desc_semestre VARCHAR(10),  
    fecha_completa DATE NOT NULL
);

CREATE TABLE DIM_CLIENTE (
    sk_dim_cliente INTEGER PRIMARY KEY,
    cod_cliente_nk INTEGER NOT NULL, 
    nb_cliente VARCHAR(150) NOT NULL,
    ci_rif VARCHAR(20) NOT NULL,
    telefono VARCHAR(20),
    direccion VARCHAR(255),
    sexo CHAR(1),
    email VARCHAR(100)
);

CREATE TABLE DIM_PRODUCTO (
    sk_dim_producto INTEGER PRIMARY KEY,
    cod_producto_nk INTEGER NOT NULL,
    nb_producto VARCHAR(100) NOT NULL,
    descrip_producto VARCHAR(255),
    cod_tipo_producto VARCHAR(50), 
    nb_tipo_producto VARCHAR(100),
    calificacion NUMERIC(3,2) 
);

CREATE TABLE DIM_CONTRATO (
    sk_dim_contrato INTEGER PRIMARY KEY,
    nro_contrato_nk INTEGER NOT NULL,
    descrip_contrato VARCHAR(255) NOT NULL
);

CREATE TABLE DIM_ESTADO_CONTRATO (
    sk_dim_estado_contrato INTEGER PRIMARY KEY,
    cod_estado VARCHAR(20) NOT NULL, 
    descrip_estado VARCHAR(50) NOT NULL 
);

CREATE TABLE DIM_EVALUACION_SERVICIO (
    sk_dim_evaluacion INTEGER PRIMARY KEY,
    cod_evaluacion_nk INTEGER NOT NULL,
    nb_descrip VARCHAR(50) NOT NULL 
);

CREATE TABLE DIM_SUCURSAL (
    sk_dim_sucursal INTEGER PRIMARY KEY,
    cod_sucursal_nk INTEGER NOT NULL,
    nb_sucursal VARCHAR(100) NOT NULL,
    cod_ciudad INTEGER,
    nb_ciudad VARCHAR(100),
    cod_pais INTEGER,
    nb_pais VARCHAR(100)
);

CREATE TABLE DIM_SINIESTRO (
    sk_dim_siniestro INTEGER PRIMARY KEY,
    nro_siniestro_nk INTEGER NOT NULL,
    descrip_siniestro VARCHAR(255) NOT NULL
);

-- 2. CREACIÓN DE TABLAS DE HECHOS (FACT)

CREATE TABLE FACT_REGISTRO_CONTRATO (
    sk_dim_tiempo_fecha_inicio INTEGER NOT NULL,
    sk_dim_tiempo_fecha_fin INTEGER NOT NULL,
    sk_dim_cliente INTEGER NOT NULL,
    sk_dim_contrato INTEGER NOT NULL,
    sk_dim_producto INTEGER NOT NULL,
    sk_dim_estado_contrato INTEGER NOT NULL,
    sk_dim_sucursal INTEGER NOT NULL, -- Corrección integrada: Para el Indicador 7
    monto NUMERIC(18,2), 
    cantidad INTEGER DEFAULT 1,
    cantidad_cliente INTEGER,
    cantidad_producto INTEGER,
    cantidad_contrato INTEGER,
    CONSTRAINT fk_fact_regcon_f_inicio FOREIGN KEY (sk_dim_tiempo_fecha_inicio) REFERENCES DIM_TIEMPO(sk_dim_tiempo),
    CONSTRAINT fk_fact_regcon_f_fin FOREIGN KEY (sk_dim_tiempo_fecha_fin) REFERENCES DIM_TIEMPO(sk_dim_tiempo),
    CONSTRAINT fk_fact_regcon_cliente FOREIGN KEY (sk_dim_cliente) REFERENCES DIM_CLIENTE(sk_dim_cliente),
    CONSTRAINT fk_fact_regcon_contrato FOREIGN KEY (sk_dim_contrato) REFERENCES DIM_CONTRATO(sk_dim_contrato),
    CONSTRAINT fk_fact_regcon_producto FOREIGN KEY (sk_dim_producto) REFERENCES DIM_PRODUCTO(sk_dim_producto),
    CONSTRAINT fk_fact_regcon_estado FOREIGN KEY (sk_dim_estado_contrato) REFERENCES DIM_ESTADO_CONTRATO(sk_dim_estado_contrato),
    CONSTRAINT fk_fact_regcon_sucursal FOREIGN KEY (sk_dim_sucursal) REFERENCES DIM_SUCURSAL(sk_dim_sucursal)
);

CREATE TABLE FACT_REGISTRO_SINIESTRO (
    sk_fecha_siniestro INTEGER NOT NULL,
    sk_fecha_respuesta INTEGER, 
    sk_dim_cliente INTEGER NOT NULL,
    sk_dim_contrato INTEGER NOT NULL,
    sk_dim_sucursal INTEGER NOT NULL,
    sk_dim_producto INTEGER NOT NULL,
    sk_dim_siniestro INTEGER NOT NULL,
    cantidad INTEGER DEFAULT 1,
    monto_reconocido NUMERIC(18,2),
    monto_solicitado NUMERIC(18,2),
    id_rechazo CHAR(2), 
    CONSTRAINT fk_fact_regsin_f_siniestro FOREIGN KEY (sk_fecha_siniestro) REFERENCES DIM_TIEMPO(sk_dim_tiempo),
    CONSTRAINT fk_fact_regsin_f_respuesta FOREIGN KEY (sk_fecha_respuesta) REFERENCES DIM_TIEMPO(sk_dim_tiempo),
    CONSTRAINT fk_fact_regsin_cliente FOREIGN KEY (sk_dim_cliente) REFERENCES DIM_CLIENTE(sk_dim_cliente),
    CONSTRAINT fk_fact_regsin_contrato FOREIGN KEY (sk_dim_contrato) REFERENCES DIM_CONTRATO(sk_dim_contrato),
    CONSTRAINT fk_fact_regsin_sucursal FOREIGN KEY (sk_dim_sucursal) REFERENCES DIM_SUCURSAL(sk_dim_sucursal),
    CONSTRAINT fk_fact_regsin_producto FOREIGN KEY (sk_dim_producto) REFERENCES DIM_PRODUCTO(sk_dim_producto),
    CONSTRAINT fk_fact_regsin_siniestro FOREIGN KEY (sk_dim_siniestro) REFERENCES DIM_SINIESTRO(sk_dim_siniestro)
);

CREATE TABLE FACT_EVALUACION_SERVICIO (
    sk_dim_tiempo_evaluacion INTEGER NOT NULL, -- Corrección integrada: Para el Indicador 9
    sk_dim_cliente INTEGER NOT NULL,
    sk_dim_producto INTEGER NOT NULL,
    sk_dim_evaluacion_servicio INTEGER NOT NULL,
    cantidad INTEGER DEFAULT 1,
    recomienda_amigo NUMERIC(5,2), 
    CONSTRAINT fk_fact_eval_tiempo FOREIGN KEY (sk_dim_tiempo_evaluacion) REFERENCES DIM_TIEMPO(sk_dim_tiempo),
    CONSTRAINT fk_fact_eval_cliente FOREIGN KEY (sk_dim_cliente) REFERENCES DIM_CLIENTE(sk_dim_cliente),
    CONSTRAINT fk_fact_eval_producto FOREIGN KEY (sk_dim_producto) REFERENCES DIM_PRODUCTO(sk_dim_producto),
    CONSTRAINT fk_fact_eval_servicio FOREIGN KEY (sk_dim_evaluacion_servicio) REFERENCES DIM_EVALUACION_SERVICIO(sk_dim_evaluacion)
);

CREATE TABLE FACT_METAS (
    sk_dim_fecha_inicio_meta INTEGER NOT NULL,
    sk_dim_fecha_fin_meta INTEGER NOT NULL,
    sk_dim_cliente INTEGER NOT NULL,
    sk_dim_producto INTEGER NOT NULL,
    sk_dim_contrato INTEGER NOT NULL,
    monto_meta_ingreso NUMERIC(18,2),
    meta_renovacion INTEGER,
    meta_asegurados INTEGER,
    CONSTRAINT fk_fact_metas_f_inicio FOREIGN KEY (sk_dim_fecha_inicio_meta) REFERENCES DIM_TIEMPO(sk_dim_tiempo),
    CONSTRAINT fk_fact_metas_f_fin FOREIGN KEY (sk_dim_fecha_fin_meta) REFERENCES DIM_TIEMPO(sk_dim_tiempo),
    CONSTRAINT fk_fact_metas_cliente FOREIGN KEY (sk_dim_cliente) REFERENCES DIM_CLIENTE(sk_dim_cliente),
    CONSTRAINT fk_fact_metas_producto FOREIGN KEY (sk_dim_producto) REFERENCES DIM_PRODUCTO(sk_dim_producto),
    CONSTRAINT fk_fact_metas_contrato FOREIGN KEY (sk_dim_contrato) REFERENCES DIM_CONTRATO(sk_dim_contrato)
);