Create User DWH identified by ERP2020;

GRANT UNLIMITED TABLESPACE TO DWH; 
CREATE SEQUENCE DWH.sqc_sk_pasajero START WITH 1 INCREMENT BY 1; --SEQ sk pasajero

CREATE TABLE DWH.SCD_2_PASAJERO(
    sk_pasajero number,
    id_pasajero number,
    nombre_completo varchar2(100),
    nacionalidad varchar2(100),
    genero varchar2(10),
    fecha_inicio date,
    fecha_fin date,
    registro_actual char(1));
    
GRANT SELECT ON ERP.PASAJEROS TO DWH;
GRANT SELECT ON ERP.NACIONALIDADES TO DWH;

SELECT 
    ID_PASAJERO,
    NOMBRE_COMPLETO,
    NACIONALIDAD,
    GENERO,
    SYSDATE FECHA_INICIO,
    TO_DATE('31/12/2050','dd/mm/yyyy')FECHA_FIN,
     'X' REGISTRO_ACTUAL
 FROM (
        SELECT 
            PSJR.ID ID_PASAJERO,
            PSJR.NOMBRE||' '||PSJR.APELLIDO NOMBRE_COMPLETO,
            NCNL.NOMBRE NACIONALIDAD, 
            DECODE(PSJR.GENERO, 'M', 'Masculino'
                                        ,'F', 'Femenino'
                                        , 'Otros') GENERO,
            DECODE (SCDP.NACIONALIDAD, NCNL.NOMBRE, 'N','S') SCD_NACIONALIDAD
          FROM ERP.PASAJEROS PSJR
        LEFT JOIN ERP.NACIONALIDADES NCNL ON PSJR.ID_NACIONALIDAD=NCNL.ID
        LEFT JOIN DWH.SCD_2_PASAJERO SCDP ON PSJR.ID=SCDP.ID_PASAJERO
        ) SCD_PASAJEROS_NEW
WHERE SCD_NACIONALIDAD='S';
;
