-- ETL2 

-- agrego una columna nueva donde van a estar todos los tiempos de vuelta rapida y otra del N° de vuelta

alter table resultados
	add VR_tiempo time(3);
alter table resultados
	add VR_numero tinyint;

-- agrego la tabla temporal

with cte as 
(
select
	MIN(Tiempo) as VueltaRapidaTiempo,
	id_carrera,
	id_piloto
		from Tiempo_de_vuelta
		group by id_carrera, id_piloto
)
,
cte2 as
(
select 
	cte.*,
	Vuelta,
	ROW_NUMBER() over (partition by VueltaRapidaTiempo, cte.id_carrera, cte.id_piloto order by VueltaRapidaTiempo) as cantidad
		from cte, Tiempo_de_vuelta
		where 
			Tiempo = VueltaRapidaTiempo
			and
			Tiempo_de_vuelta.id_carrera = cte.id_carrera
			and
			Tiempo_de_vuelta.id_piloto = cte.id_piloto
)

select id_carrera, id_piloto, Vuelta, VueltaRapidaTiempo into TdV_temporal from cte2 where cantidad = 1

-- inserto los datos de la tabla temporal a las columnas nuevas de la tabla original

--		TIEMPOS DE VUELTA RAPIDA
--inserto los tiempos de vuelta rapida nuevas

update Resultados set VR_tiempo = VueltaRapidaTiempo from TdV_temporal
														where 
															VueltaRapida_Tiempo is null
															and
															Resultados.id_carrera = TdV_temporal.id_carrera
															and
															Resultados.id_piloto = TdV_temporal.id_piloto
;

--inserto los tiempos de vuelta rapida ya existentes															
										
update Resultados set VR_tiempo = VueltaRapida_Tiempo where VR_tiempo is null
															
select VueltaRapida_Tiempo, VR_tiempo from Resultados		

--		VUELTA RAPIDA

--inserto los N° de tiempos de vuelta rapida nuevas
update Resultados set [VR_numero] = [Vuelta] from TdV_temporal
														where 
															[VueltaRapida] is null
															and
															Resultados.id_carrera = TdV_temporal.id_carrera
															and
															Resultados.id_piloto = TdV_temporal.id_piloto
;

--inserto los tiempos de vuelta rapida ya existentes															
update Resultados set [VR_numero] = [VueltaRapida] where [VR_numero] is null;

select [VR_numero], [VueltaRapida] from Resultados
;

-- elimino las columnas viejas

alter table resultados
	drop column [VueltaRapida], [VueltaRapida_Tiempo];

-- elimino la tabla temporal

drop table TdV_temporal;

--cambio el nombre de las columnas nuevas

exec sp_rename 'Resultados.VR_tiempo', 'VueltaRapida_Tiempo';
exec sp_rename 'Resultados.VR_numero', 'VueltaRapida_Numero'

-- INSERTO COLUMNA DE BANDERA PARA LOS CONSTRUCTORES

Alter table constructores
	add Banderas_jpg varchar(255);

update Constructores set banderas_jpg = case
											when Nacionalidad = 'Irlandesa' then 'https://drive.google.com/thumbnail?id=1MexfgtXsOppu-P3jpJLXfeyjyTOdLI4M'
											when Nacionalidad = 'Suiza' then 'https://drive.google.com/thumbnail?id=1cVraX36he1HeroO9Yom1heXJz4zV-tim'
											when Nacionalidad = 'Rusa' then 'https://drive.google.com/thumbnail?id=1miR09tFoRd7dBPvt6V47b4sFvQXGHL77'
											when Nacionalidad = 'Estadounidense' then 'https://drive.google.com/thumbnail?id=1oJabIrX9TqK58897jzY90ljr10l203yi'
											when Nacionalidad = 'Francesa' then 'https://drive.google.com/thumbnail?id=1z9LL-fdn0SZMrPLAZk3FZWlGHwHY-B0b'
											when Nacionalidad = 'Española' then 'https://drive.google.com/thumbnail?id=1w_28fYbuZcR1bVZcjaGn8l8aNqOjgMgA'
											when Nacionalidad = 'Japonesa' then 'https://drive.google.com/thumbnail?id=1OZn85D2vUYkKZltzj4t19nlG9OkfFJgZ'
											when Nacionalidad = 'Británica' then 'https://drive.google.com/thumbnail?id=1K0pon_iVyFXAh7T6JS-2Hxrpf1mHR0bR'
											when Nacionalidad = 'India' then 'https://drive.google.com/thumbnail?id=1bjdgqao_o133Crqi4EuAFK4BVC01F6Jj'
											when Nacionalidad = 'italiana' then 'https://drive.google.com/thumbnail?id=1Cq_Biwm-tIUPGMDfzxbxQEk1zbq9MoTm'
											when Nacionalidad = 'austríaca' then 'https://drive.google.com/thumbnail?id=1bdFrlO5YAyXsRdYRVAP8sMSnug195qdj'
											when Nacionalidad = 'malasia' then 'https://drive.google.com/thumbnail?id=1R4xwec3nfzwjRfKnXll37nTCIvhP3qxd'
											when Nacionalidad = 'Neerlandesa' then 'https://drive.google.com/thumbnail?id=1t-3L_bz4Uz1ok6DpOo4BHLjzO8uS3LP4'
											when Nacionalidad = 'Alemana' then 'https://drive.google.com/thumbnail?id=1nSfMetYiGSpf1OseVido-2r3zDbUoATr'
										end
;

-- Inserto una tabla temporal dbo.BanderaPaises con todas las URL pertenecientes a las imagenes de las banderas

-- Creo la columna donde voy a insertar los datos URL
Alter table Pilotos
add Banderas_png varchar(255);

update Pilotos set banderas_png = [url] from banderapaises where Pilotos.Nacionalidad = banderaPaises.Nacionalidad;
