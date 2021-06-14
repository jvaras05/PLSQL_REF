CREATE OR REPLACE PACKAGE C##MASTER.PKG_CLIENTES
AS
    /******************************************************************************
   NAME:       Package Sistema Bancario
   PURPOSE:    Crear un nuevo cliente, crear una nueva cuenta a partir de un cliente creado y enviar transferencias entre cuentas.
                      

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        22-08-2020 Jorge Varas     1. Se crea package con procedimientos para crear clientes, cuentas, transferencias. 
  
******************************************************************************/
  
     /*Funcion para calular la edad de un cliente en base a su fecha de nacimiento */   
     FUNCTION CALCULAR_EDAD (pfecha_nac CLIENTES_BANCO.FECHA_NACIMIENTO%TYPE)
      RETURN NUMBER;
    
    
    /* Procedimiento para crear un nuevo cliente
            Validaciones a considerar:
                1 Cliente no esté previamente creado por su RUT
                2 Nombre y apellidos no contengan números
                3 Debe tener al menos 18 años*/
   PROCEDURE INGRESO_CLIENTES (
      prut                 CLIENTES_BANCO.RUT%TYPE,
      pnombre              CLIENTES_BANCO.NOMBRE%TYPE,
      papellido_paterno    CLIENTES_BANCO.APELLIDO_PATERNO%TYPE,
      papellido_materno    CLIENTES_BANCO.APELLIDO_MATERNO%TYPE,
      pfecha_nacimiento    CLIENTES_BANCO.FECHA_NACIMIENTO%TYPE);

    /* Procedimiento para crear una nueva cuenta
            Validaciones a considerar:
                1 Si tiene otra cuenta, su sobre-giro en las demás cuentas no debe estar utilizado
                2 Si tiene otra cuenta, debe tener al menos una con saldo contable mayor a cero
                3 Si el tipo de cuenta es “Cuenta Corriente”, e cliente debe tener al menos 21 años
                4 En caso de aplicar sobre-giro, el monto por default debe ser $300.000*/
   PROCEDURE CREAR_CUENTA (prut              CLIENTES_BANCO.RUT%TYPE,
                           pnombre_cuenta    TIPO_CUENTAS.NOMBRE%TYPE);

    /* Procedimiento para realizar transferencias
            Validaciones a considerar:
                1 Saldo + saldo sobre-giro <= monto a transferir
                2 Tarjeta actual de cuenta de origen debe estar activa (estado = ‘A’)
                3 Debe recibir la clave de cajero y comparar si esta coincide
                4 Insertar registro de movimiento tanto cuenta de origen como en el destino
                5 Monto a transferir no debe exceder el máximo según el tipo de cuenta*/
   PROCEDURE CREAR_TRANSFERENCIA (
      pnumero_tarjeta           TARJETAS.NUMERO_TARJETA%TYPE,
      pmes_agno_expiracion      CHAR,
      pclave_cajero             TARJETAS.CLAVE_CAJERO%TYPE,
      prut_cuenta_destino       CLIENTES_BANCO.RUT%TYPE,
      pnumero_cuenta_destino    CUENTAS.ID_CUENTA%TYPE,
      pmonto                    MOVIMIENTOS.MONTO%TYPE);
END;

CREATE OR REPLACE PACKAGE BODY C##MASTER.PKG_CLIENTES
AS
   FUNCTION CALCULAR_EDAD (pfecha_nac CLIENTES_BANCO.FECHA_NACIMIENTO%TYPE)
      RETURN NUMBER
   IS
      vedad   NUMBER;
   BEGIN
      vedad := FLOOR ( (SYSDATE - pfecha_nac) / 365.25);
      RETURN vedad;
   END;


   PROCEDURE INGRESO_CLIENTES (
      prut                 CLIENTES_BANCO.RUT%TYPE,
      pnombre              CLIENTES_BANCO.NOMBRE%TYPE,
      papellido_paterno    CLIENTES_BANCO.APELLIDO_PATERNO%TYPE,
      papellido_materno    CLIENTES_BANCO.APELLIDO_MATERNO%TYPE,
      pfecha_nacimiento    CLIENTES_BANCO.FECHA_NACIMIENTO%TYPE)
   IS
      verror_contiene_numeros   EXCEPTION;
      verror_cumple_edad        EXCEPTION;
   BEGIN
      IF NOT REGEXP_LIKE (pnombre || papellido_paterno || papellido_materno,
                          '[0-9]',
                          'i')
      THEN
         IF PKG_CLIENTES.CALCULAR_EDAD (pfecha_nacimiento) >= 18
         THEN
            INSERT INTO clientes_banco
                 VALUES (C##MASTER.sqc_id_cliente.NEXTVAL,
                         prut,
                         pnombre,
                         papellido_paterno,
                         papellido_materno,
                         pfecha_nacimiento);

            DBMS_OUTPUT.put_line ('cliente creado!');
            COMMIT;
         ELSE
            RAISE verror_cumple_edad;
         END IF;
      ELSE
         RAISE verror_contiene_numeros;
      END IF;
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         DBMS_OUTPUT.put_line ('el rut del cliente ya existe!');
         ROLLBACK;
      WHEN verror_contiene_numeros
      THEN
         DBMS_OUTPUT.put_line (
            'el nombre completo no debe contener numeros!');
         ROLLBACK;
      WHEN verror_cumple_edad
      THEN
         DBMS_OUTPUT.put_line ('la edad debe ser mayor o igual a 18 años!');
         ROLLBACK;
   END;

   PROCEDURE CREAR_CUENTA (prut              CLIENTES_BANCO.RUT%TYPE,
                           pnombre_cuenta    TIPO_CUENTAS.NOMBRE%TYPE)
   IS
      vfecha_nac             CLIENTES_BANCO.FECHA_NACIMIENTO%TYPE;
      vid_cliente            CLIENTES_BANCO.ID_CLIENTE%TYPE;
      vsobregiro_utilizado   NUMBER;
      vsaldo_contable        NUMBER;
      vcant_cuentas          NUMBER;
      vid_tipo_cuenta        NUMBER;
      vmax_sobregiro         CUENTAS.MAX_SOBREGIRO%TYPE;
      err_cumple_edad        EXCEPTION;
      err_sobregiro_util     EXCEPTION;
      err_saldo_contable     EXCEPTION;
   BEGIN
      vsobregiro_utilizado := 0;

      SELECT ID_CLIENTE, FECHA_NACIMIENTO
        INTO vid_cliente, vfecha_nac
        FROM CLIENTES_BANCO
       WHERE RUT = prut;

      SELECT ID_TIPO_CUENTA, DECODE (IND_SOBREGIRO, 'Y', 300000, 0)
        INTO vid_tipo_cuenta, vmax_sobregiro
        FROM TIPO_CUENTAS
       WHERE NOMBRE = pnombre_cuenta;

      IF pnombre_cuenta = 'CUENTA CORRIENTE'
         AND PKG_CLIENTES.CALCULAR_EDAD (vfecha_nac) < 21
      THEN
         RAISE err_cumple_edad;
      END IF;

      SELECT NVL (SUM (MAX_SOBREGIRO - SALDO_SOBREGIRO), 0),
             NVL (SUM (SALDO_CONTABLE), 0),
             COUNT (1)
        INTO vsobregiro_utilizado, vsaldo_contable, vcant_cuentas
        FROM CUENTAS
       WHERE ID_CLIENTE = vid_cliente;

      IF vcant_cuentas > 0
      THEN
         IF vsobregiro_utilizado > 0
         THEN
            RAISE err_sobregiro_util;
         END IF;

         IF vsaldo_contable = 0
         THEN
            RAISE err_saldo_contable;
         END IF;
      END IF;

      INSERT INTO CUENTAS
           VALUES (C##FINANZAS.sqc_id_cuenta.NEXTVAL,
                   vid_cliente,
                   vid_tipo_cuenta,
                   SYSDATE,
                   'A',
                   0,
                   vmax_sobregiro,
                   vmax_sobregiro);

      DBMS_OUTPUT.put_line ('Cuenta creada!');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         DBMS_OUTPUT.put_line ('El cliente o tipo de cuenta no existe');
      WHEN err_cumple_edad
      THEN
         DBMS_OUTPUT.put_line ('El cliente tiene menos de 21 años');
      WHEN err_sobregiro_util
      THEN
         DBMS_OUTPUT.put_line ('El cliente tiene sobregiro en otra cuenta');
      WHEN err_saldo_contable
      THEN
         DBMS_OUTPUT.put_line ('El cliente tiene saldo insuficiente');
   END;

   PROCEDURE CREAR_TRANSFERENCIA (
      pnumero_tarjeta           TARJETAS.NUMERO_TARJETA%TYPE,
      pmes_agno_expiracion      CHAR,
      pclave_cajero             TARJETAS.CLAVE_CAJERO%TYPE,
      prut_cuenta_destino       CLIENTES_BANCO.RUT%TYPE,
      pnumero_cuenta_destino    CUENTAS.ID_CUENTA%TYPE,
      pmonto                    MOVIMIENTOS.MONTO%TYPE)
   IS
      -- Variables internas
      vtarjeta_activa           TARJETAS.ESTADO%TYPE;
      vclave_cajero             TARJETAS.CLAVE_CAJERO%TYPE;
      vsaldo_total_cliente      NUMBER;
      vmax_trx_monto            TIPO_CUENTAS.MAX_TRX_MONTO%TYPE;
      vid_cuenta                CUENTAS.ID_CUENTA%TYPE;

      -- Variables de error
      verror_tarjeta_inactiva   EXCEPTION;
      verror_clave_erronea      EXCEPTION;
      verror_excede_saldo       EXCEPTION;
      verror_max_monto          EXCEPTION;
   BEGIN
      SELECT tarj.estado,
             tarj.clave_cajero,
             (cuen.saldo_contable + cuen.saldo_sobregiro),
             t_cuen.max_trx_monto,
             cuen.id_cuenta
        INTO vtarjeta_activa,
             vclave_cajero,
             vsaldo_total_cliente,
             vmax_trx_monto,
             vid_cuenta
        FROM TARJETAS tarj
             INNER JOIN CUENTAS cuen
                ON tarj.id_cuenta = cuen.id_cuenta
             INNER JOIN tipo_cuentas t_cuen
                ON cuen.id_tipo_cuenta = t_cuen.id_tipo_cuenta
       WHERE tarj.numero_tarjeta = pnumero_tarjeta;


      IF vtarjeta_activa != 'A'
      THEN
         RAISE verror_tarjeta_inactiva;
      END IF;

      IF vclave_cajero != pclave_cajero
      THEN
         RAISE verror_clave_erronea;
      END IF;

      IF vsaldo_total_cliente < pmonto
      THEN
         RAISE verror_excede_saldo;
      END IF;

      IF pmonto > vmax_trx_monto
      THEN
         RAISE verror_max_monto;
      END IF;

      UPDATE cuentas
         SET saldo_contable =
                CASE
                   WHEN saldo_contable <= pmonto THEN 0
                   ELSE saldo_contable - pmonto
                END,
             saldo_sobregiro =
                CASE
                   WHEN saldo_contable <= pmonto
                   THEN
                      (saldo_sobregiro - (pmonto - saldo_contable))
                   ELSE
                      saldo_sobregiro
                END
       WHERE EXISTS
                (SELECT 1
                   FROM tarjetas tarj
                  WHERE tarj.numero_tarjeta = pnumero_tarjeta);

      UPDATE cuentas
         SET saldo_contable = saldo_contable - pmonto
       WHERE id_cuenta = pnumero_cuenta_destino;

      INSERT INTO movimientos
           VALUES (C##FINANZAS.SQC_ID_MOV.NEXTVAL,
                   vid_cuenta,
                   SYSDATE,
                   2,
                   'C',
                   pmonto,
                   'TRANSFERENCIA TERCEROS');

      INSERT INTO movimientos
           VALUES (C##FINANZAS.SQC_ID_MOV.NEXTVAL,
                   pnumero_cuenta_destino,
                   SYSDATE,
                   2,
                   'A',
                   pmonto,
                   'TRANSFERENCIA TERCEROS');

      COMMIT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         DBMS_OUTPUT.put_line ('la tarjeta no existe!');
      WHEN verror_tarjeta_inactiva
      THEN
         DBMS_OUTPUT.put_line ('la tarjeta no esta activa!');
      WHEN verror_clave_erronea
      THEN
         DBMS_OUTPUT.put_line ('la clave ingresada no es correcta!');
      WHEN verror_excede_saldo
      THEN
         DBMS_OUTPUT.put_line (
            'El monto excede el saldo disponible de la tarjeta!');
      WHEN verror_max_monto
      THEN
         DBMS_OUTPUT.put_line ('El monto excede lo autorizado!');
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('Fallo la transaccion!');
         ROLLBACK;
   END;
END;