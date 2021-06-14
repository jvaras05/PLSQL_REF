CREATE OR REPLACE PACKAGE DWH.PKG_DIMENSIONES AS
    PROCEDURE TRF_SCD_2_PASAJEROS;
END;

CREATE OR REPLACE PACKAGE BODY DWH.PKG_DIMENSIONES AS

        PROCEDURE TRF_SCD_2_PASAJEROS IS
        BEGIN
            
            for pasajero in (SELECT * FROM DWH.V_SCD_2_PASAJEROS_NEW) loop
                /*Actualizando datos*/
                update DWH.SCD_2_PASAJERO 
                    SET registro_actual=null, fecha_fin=sysdate 
                    WHERE id_pasajero=pasajero.id_pasajero;

                    /*Update SCD*/
                    insert into DWH.SCD_2_PASAJERO VALUES (
                                                                                    DWH.sqc_sk_pasajero.nextval,
                                                                                    pasajero.id_pasajero, 
                                                                                    pasajero.nombre_completo,
                                                                                    pasajero.nacionalidad,
                                                                                    pasajero.genero,
                                                                                    pasajero.fecha_inicio,
                                                                                    pasajero.fecha_fin,
                                                                                    pasajero.registro_actual);
                                                               
            end loop;
         commit;
        END;
END; --END PACKAGE
