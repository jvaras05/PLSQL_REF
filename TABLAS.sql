--Master
CREATE SEQUENCE C##MASTER.sqc_id_cliente START WITH 1 INCREMENT BY 1; --SEQ Id Cliente
CREATE SEQUENCE C##MASTER.sqc_id_tipo_cta START WITH 1 INCREMENT BY 1; --SEQ Id tipo cuenta
CREATE SEQUENCE C##MASTER.sqc_id_tipo_mov START WITH 1 INCREMENT BY 1; -- SEQ Id tipo movimiento

CREATE SEQUENCE C##FINANZAS.sqc_id_cuenta START WITH 1 INCREMENT BY 1; -- SEQ Id cuenta
CREATE SEQUENCE C##FINANZAS.sqc_id_tarjeta START WITH 1 INCREMENT BY 1; -- SEQ Id tarjeta
CREATE SEQUENCE C##FINANZAS.sqc_id_mov START WITH 1 INCREMENT BY 1; -- SEQ Id movimiento

--Tablas del Schema Master
CREATE TABLE C##MASTER.CLIENTES_BANCO
(
   id_cliente         NUMBER NOT NULL,
   rut                VARCHAR (12) NOT NULL,
   nombre             VARCHAR (60) NOT NULL,
   apellido_paterno   VARCHAR (50) NOT NULL,
   apellido_materno   VARCHAR (50) NOT NULL,
   fecha_nacimiento   DATE NOT NULL
);

CREATE TABLE C##MASTER.TIPO_CUENTAS
(
   id_tipo_cuenta   NUMBER NOT NULL,
   nombre           VARCHAR (20) NOT NULL,
   max_giros        NUMBER NOT NULL,
   max_trx_monto    NUMBER NOT NULL,
   ind_sobregiro    CHAR (1) NOT NULL
);

CREATE TABLE C##MASTER.TIPO_MOVIMIENTOS
(
   id_tipo_movimiento   NUMBER NOT NULL,
   nombre               VARCHAR (50) NOT NULL
);

--Tablas del Schema Finanzas
CREATE TABLE C##FINANZAS.CUENTAS
(
   id_cuenta         NUMBER NOT NULL,
   id_cliente        NUMBER NOT NULL,
   id_tipo_cuenta    NUMBER NOT NULL,
   fecha_apertura    DATE NOT NULL,
   estado            CHAR (1) NOT NULL,
   saldo_contable    NUMBER NOT NULL,
   saldo_sobregiro   NUMBER NOT NULL,
   max_sobregiro     NUMBER NOT NULL
);

CREATE TABLE C##FINANZAS.TARJETAS
(
   id_tarjeta         NUMBER NOT NULL,
   id_cuenta          NUMBER NOT NULL,
   numero_tarjeta     CHAR (16) NOT NULL,
   fecha_expiracion   DATE NOT NULL,
   estado             CHAR (1) NOT NULL,
   clave_cajero       CHAR (4) NOT NULL
);

CREATE TABLE C##FINANZAS.MOVIMIENTOS
(
   id_movimiento        NUMBER NOT NULL,
   id_cuenta_origen     NUMBER NOT NULL,
   fecha_transaccion    DATE NOT NULL,
   id_tipo_movimiento   NUMBER NOT NULL,
   ind_cargo_abono      CHAR (1) NOT NULL,
   monto                NUMBER NOT NULL,
   glosa                VARCHAR (100) NOT NULL
);