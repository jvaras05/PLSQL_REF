CREATE VIEW DWH.V_SCD_2_PASAJEROS_NEW AS
SELECT ID_PASAJERO,
       NOMBRE_COMPLETO,
       NACIONALIDAD,
       GENERO,
       SYSDATE FECHA_INICIO,
       TO_DATE ('31/12/2050', 'dd/mm/yyyy') FECHA_FIN,
       'X' REGISTRO_ACTUAL
  FROM (SELECT PSJR.ID ID_PASAJERO,
               PSJR.NOMBRE || ' ' || PSJR.APELLIDO NOMBRE_COMPLETO,
               NCNL.NOMBRE NACIONALIDAD,
               DECODE (PSJR.GENERO,
                       'M', 'Masculino',
                       'F', 'Femenino',
                       'Otros')
                  GENERO,
               DECODE (SCDP.NACIONALIDAD, NCNL.NOMBRE, 'N', 'S')
                  SCD_NACIONALIDAD
          FROM ERP.PASAJEROS PSJR
               LEFT JOIN ERP.NACIONALIDADES NCNL
                  ON PSJR.ID_NACIONALIDAD = NCNL.ID
               LEFT JOIN DWH.SCD_2_PASAJERO SCDP
                  ON PSJR.ID = SCDP.ID_PASAJERO) SCD_PASAJEROS_NEW
 WHERE SCD_NACIONALIDAD = 'S';