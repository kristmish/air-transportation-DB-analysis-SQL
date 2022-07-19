set search_path to bookings

-- Задание №1
-- В каких городах больше одного аэропорта?
-- Ответ: в Москве и Ульяновске больше 1 аэропорта
-- Логика запроса: из таблицы airports группируем данные по городам и используем агрегатную функцию count (подсчет количества строк) для подсчета количества аэропортов по городам.
-- далее сортируем данные по количеству от большего к меньшему.

select city, count(airport_code) as "airports_quantity"
from airports
group by city
order by 2 desc


-- Задание №2
-- В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
-- Ответ: запрос представлен ниже
-- Логика запроса: таблицу flights (содержит информацию по всем рейсам) присоединяем к таблице aircrafts (содержит информацию о моделях и дальности полёта самолетов).
-- из объединенной таблицы выводим информацию о наименовании аэропорта, модели самолета и дальности полета конткретной модели. Далее при помощи оператора where выводим информацию только
-- по самолёту с максимальной дальностью (при использовании вложенного запроса).

select distinct(departure_airport), airport_name as "departure_airport_name", arrival_airport, model, range
from flights
join aircrafts on flights.aircraft_code = aircrafts.aircraft_code
join airports on departure_airport = airport_code
where range = (
	  select max(range)
	  from aircrafts)
	  

-- Задание №3
-- Вывести 10 рейсов с максимальным временем задержки вылета
-- Ответ: запрос представлен ниже
-- Логика запроса: из таблицы flights выбираем только рейсы со статусом Departed, Arrived (то есть только те рейсы, где есть время отправления). Выводим вычисляемую колонку разницу между
-- запланированным временем вылета и фактическим временем вылета и сортируем её по убыванию. При помощи оператора limit выводим Топ-10 рейсов с максимальным временем задержки вылета.

	  
select flight_id, flight_no, scheduled_departure, actual_departure, (actual_departure - scheduled_departure) as delay_time
from flights
where status = 'Departed' or status = 'Arrived'
order by delay_time desc
limit 10


-- Задание №4
-- Были ли брони, по которым не были получены посадочные талоны?
-- Ответ: запрос представлен ниже. Да, есть брони, по которым не были получены посадочные талоны
-- Логика запроса: объединяем таблицы bookings, tickets, ticket_flights, boarding_passes таким образом, чтобы все данные из таблицы bookings сохранились (то есть используем left join).
-- далее ищем бронирования, по которым нет посадочных талонов (то есть в колонке с номером посадочного талона должно быть пусто).


select bookings.book_ref, book_date, boarding_no, bp.ticket_no
from bookings
left join tickets on bookings.book_ref = tickets.book_ref 
left join ticket_flights tf on tickets.ticket_no = tf.ticket_no 
left join boarding_passes bp on tf.ticket_no = bp.ticket_no
where boarding_no is null


-- Задание №5
-- Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
-- Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
-- Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня.
-- Ответ: запрос представлен ниже
-- Логика запроса: Сначала создаем временную таблицу, где выводим общее количество мест в каждой модели самолета. Вторая временная таблица содержит информацию о количестве выданных посадочных
-- талонов (предполагаем, что если посадочный талон выдан, то человек 100% улетит и место будет занято). Далее присоединяем 2 временные таблицы к таблицы flights, где содержится информация
-- по всем рейсам. Из созданной таблицы выводим информацию о номере рейса, дате вылета, наименовании аэропорта, количестве мест в самолете, занятых местах, расчетные колонки по количеству
-- свободных мест и доле свободных мест от общего количества мест в самолете. также через оконную функцию выводим информацию о количестве вывезенных пассажиров в разерзе аэропортов и дат.
-- сортируем всю информацию по дате вылета.


with cte1 as (
	select distinct(aircrafts.aircraft_code), model, 
      count(seat_no) over (partition by aircrafts.aircraft_code) as total_seats_quantity
	from aircrafts
	left join seats on aircrafts.aircraft_code = seats.aircraft_code),
	cte2 as (
	select distinct(flight_id),
	  count(boarding_no) over (partition by flight_id) as taken_seats
	from boarding_passes)
select flights.flight_id, flights.flight_no, flights.scheduled_departure, flights.departure_airport, flights.aircraft_code, total_seats_quantity, taken_seats, 
		(total_seats_quantity - taken_seats) as free_seats, ((total_seats_quantity - taken_seats)::numeric / total_seats_quantity * 100) as "%_seats",
		sum(taken_seats) over (partition by departure_airport, flights.scheduled_departure::date  order by flights.scheduled_departure) as departured_people_quantity
from flights
join cte1 on cte1.aircraft_code = flights.aircraft_code
join cte2 on cte2.flight_id = flights.flight_id
where status = 'Departed' or status = 'Arrived'
order by flights.scheduled_departure 



-- Задание №6
-- Найдите процентное соотношение перелетов по типам самолетов от общего количества.
-- Ответ: запрос представлен ниже
-- Логика запроса: создаем окононные функции по подсчету общего количества перелетов и перелетов по модели самолета. Перед этим присоединяем таблицу aircrafts к таблице flights. 
-- Также выводим расчетную колонку, где показываем долю перелетов по каждой моделе самолета. 


select distinct(aircrafts.aircraft_code), aircrafts.model,
	count (flights.flight_id) over () as total_quantity_flights,
	count (flights.flight_id) over (partition by flights.aircraft_code) as quantity_per_model,
	round((count (flights.flight_id) over (partition by flights.aircraft_code)::numeric / count (flights.flight_id) over ()) * 100, 2) as "%_of_flights"
from aircrafts
join flights on aircrafts.aircraft_code = flights.aircraft_code 


-- Задание №7
-- Были ли города, в которые можно добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
-- Ответ: запрос представлен ниже
-- Логика запроса: создаем 2 временные таблицы: одна табоица содержит информацию по стоимости билетов эконом класса с указанием аэропорта прибытия, вторая - 
-- информацию по билетам бизнес класса. далее объединяем 2 таблицы и выодим расчетную колонку, поазывающую разницу между стоимостью билета бизнес класса и эконом класса.
-- выводим только те рейсы, где разница меньше 0 (то есть стоимость билета эконом класса была выше, чем билета бизнесс класса)


with cte1 as(
	select flights.flight_no, flights.arrival_airport, airports.city, fare_conditions as fare_condition_economy, amount as amount_economy
	from flights
	join ticket_flights tf on flights.flight_id = tf.flight_id
	join airports on flights.arrival_airport = airports.airport_code
	where fare_conditions = 'Economy'),
	cte2 as (select flights.flight_no, flights.arrival_airport, airports.city, fare_conditions as fare_condition_business, amount as amount_business
	from flights
	join ticket_flights tf on flights.flight_id = tf.flight_id
	join airports on flights.arrival_airport = airports.airport_code
	where fare_conditions = 'Business')
select cte1.flight_no, cte1.arrival_airport, cte1.city, fare_condition_economy, amount_economy, fare_condition_business, amount_business, (amount_business - amount_economy) as price_diff
from cte1
join cte2 on cte1.flight_no = cte2.flight_no
where (amount_business - amount_economy) < 0


-- Задание №8
-- Между какими городами нет прямых рейсов?
-- Ответ: запрос представлен ниже
-- Логика запроса: создаем представление, где отражены все возможные пары аэропортов прибытия и вылета. Далее к таблице flights присоединяем таблицу airports отдельно по аэропортам прибытия
-- и по аэропортам вылета, чтобы указать корректные наименования. После при помощи оператора except из созданного представления, содержащий массив всех возможных пар аэропортов 
-- убираем массив пар аэропортов, между которыми фактически был осуществлен перелет. Тем самым получаем новый массив, содержащий пары ажропортов, между которого в нашей БД нет информации
-- о прямом рейсе.

create view depart_arrival_airports as
	select distinct dpt.airport_code as departure_airport, dpt.airport_name as departure_airport_name, arvl.airport_code as arrival_airport, arvl.airport_name as arrival_airport_name
	from airports as dpt, airports as arvl
	
select *
from depart_arrival_airports
except
select distinct a_departure.airport_code, a_departure.airport_name, a_arrival.airport_code, a_arrival.airport_name
from flights
join airports a_departure on flights.departure_airport = a_departure.airport_code
join airports a_arrival on flights.arrival_airport = a_arrival.airport_code 


-- Задание №9
-- Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы
-- Ответ: запрос представлен ниже
-- Логика запроса: к таблице flights присоединяем к таблице airports, чтобы определить расположение аэропортов вылета и прибытия, также присоединяем таблицу aircrafts, чтобы
-- вывести значение дальности самолета для того или иного рейса. далее, используя формулу расчета расстояния, выводим расчетную колонку со значением расстояния между аэропортами
-- и при помощи оператора case выводим колокнку, где указывается результат сравнения расчетного расстояния с допустимой максимальной дальностю перелета.

select distinct a_departure.airport_code as departure_airport, a_departure.airport_name as departure_airport_name, a_arrival.airport_code as arrival_airport, a_arrival.airport_name as arrival_airport_name,
a_departure.longitude as departure_longitude, a_departure.latitude as departure_latitude, a_arrival.longitude as arrival_longitude, a_arrival.latitude as arrival_latitude,
sind(a_departure.latitude) * sind(a_arrival.latitude) + cosd(a_departure.longitude) * cosd(a_arrival.longitude) * cosd(a_departure.longitude - a_arrival.longitude) as distance_in_radians,
sind(a_departure.latitude) * sind(a_arrival.latitude) + cosd(a_departure.longitude) * cosd(a_arrival.longitude) * cosd(a_departure.longitude - a_arrival.longitude) * 6371 as distance_in_km,
aircrafts.range,
	case
		when aircrafts.range > sind(a_departure.latitude) * sind(a_arrival.latitude) + cosd(a_departure.longitude) * cosd(a_arrival.longitude) * cosd(a_departure.longitude - a_arrival.longitude) * 6371 then 'расстояние больше дальности'
		else 'расстояние меньше дальности'
	end diff_with_range
from flights
join airports a_departure on flights.departure_airport = a_departure.airport_code
join airports a_arrival on flights.arrival_airport = a_arrival.airport_code 
join aircrafts on flights.aircraft_code = aircrafts.aircraft_code
	 


