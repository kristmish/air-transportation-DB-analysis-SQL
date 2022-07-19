set search_path to bookings

-- ������� �1
-- � ����� ������� ������ ������ ���������?
-- �����: � ������ � ���������� ������ 1 ���������
-- ������ �������: �� ������� airports ���������� ������ �� ������� � ���������� ���������� ������� count (������� ���������� �����) ��� �������� ���������� ���������� �� �������.
-- ����� ��������� ������ �� ���������� �� �������� � ��������.

select city, count(airport_code) as "airports_quantity"
from airports
group by city
order by 2 desc


-- ������� �2
-- � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?
-- �����: ������ ����������� ����
-- ������ �������: ������� flights (�������� ���������� �� ���� ������) ������������ � ������� aircrafts (�������� ���������� � ������� � ��������� ����� ���������).
-- �� ������������ ������� ������� ���������� � ������������ ���������, ������ �������� � ��������� ������ ����������� ������. ����� ��� ������ ��������� where ������� ���������� ������
-- �� ������� � ������������ ���������� (��� ������������� ���������� �������).

select distinct(departure_airport), airport_name as "departure_airport_name", arrival_airport, model, range
from flights
join aircrafts on flights.aircraft_code = aircrafts.aircraft_code
join airports on departure_airport = airport_code
where range = (
	  select max(range)
	  from aircrafts)
	  

-- ������� �3
-- ������� 10 ������ � ������������ �������� �������� ������
-- �����: ������ ����������� ����
-- ������ �������: �� ������� flights �������� ������ ����� �� �������� Departed, Arrived (�� ���� ������ �� �����, ��� ���� ����� �����������). ������� ����������� ������� ������� �����
-- ��������������� �������� ������ � ����������� �������� ������ � ��������� � �� ��������. ��� ������ ��������� limit ������� ���-10 ������ � ������������ �������� �������� ������.

	  
select flight_id, flight_no, scheduled_departure, actual_departure, (actual_departure - scheduled_departure) as delay_time
from flights
where status = 'Departed' or status = 'Arrived'
order by delay_time desc
limit 10


-- ������� �4
-- ���� �� �����, �� ������� �� ���� �������� ���������� ������?
-- �����: ������ ����������� ����. ��, ���� �����, �� ������� �� ���� �������� ���������� ������
-- ������ �������: ���������� ������� bookings, tickets, ticket_flights, boarding_passes ����� �������, ����� ��� ������ �� ������� bookings ����������� (�� ���� ���������� left join).
-- ����� ���� ������������, �� ������� ��� ���������� ������� (�� ���� � ������� � ������� ����������� ������ ������ ���� �����).


select bookings.book_ref, book_date, boarding_no, bp.ticket_no
from bookings
left join tickets on bookings.book_ref = tickets.book_ref 
left join ticket_flights tf on tickets.ticket_no = tf.ticket_no 
left join boarding_passes bp on tf.ticket_no = bp.ticket_no
where boarding_no is null


-- ������� �5
-- ������� ���������� ��������� ���� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
-- �������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. 
-- �.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ � ������� ���.
-- �����: ������ ����������� ����
-- ������ �������: ������� ������� ��������� �������, ��� ������� ����� ���������� ���� � ������ ������ ��������. ������ ��������� ������� �������� ���������� � ���������� �������� ����������
-- ������� (������������, ��� ���� ���������� ����� �����, �� ������� 100% ������ � ����� ����� ������). ����� ������������ 2 ��������� ������� � ������� flights, ��� ���������� ����������
-- �� ���� ������. �� ��������� ������� ������� ���������� � ������ �����, ���� ������, ������������ ���������, ���������� ���� � ��������, ������� ������, ��������� ������� �� ����������
-- ��������� ���� � ���� ��������� ���� �� ������ ���������� ���� � ��������. ����� ����� ������� ������� ������� ���������� � ���������� ���������� ���������� � ������� ���������� � ���.
-- ��������� ��� ���������� �� ���� ������.


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



-- ������� �6
-- ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.
-- �����: ������ ����������� ����
-- ������ �������: ������� ��������� ������� �� �������� ������ ���������� ��������� � ��������� �� ������ ��������. ����� ���� ������������ ������� aircrafts � ������� flights. 
-- ����� ������� ��������� �������, ��� ���������� ���� ��������� �� ������ ������ ��������. 


select distinct(aircrafts.aircraft_code), aircrafts.model,
	count (flights.flight_id) over () as total_quantity_flights,
	count (flights.flight_id) over (partition by flights.aircraft_code) as quantity_per_model,
	round((count (flights.flight_id) over (partition by flights.aircraft_code)::numeric / count (flights.flight_id) over ()) * 100, 2) as "%_of_flights"
from aircrafts
join flights on aircrafts.aircraft_code = flights.aircraft_code 


-- ������� �7
-- ���� �� ������, � ������� ����� ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?
-- �����: ������ ����������� ����
-- ������ �������: ������� 2 ��������� �������: ���� ������� �������� ���������� �� ��������� ������� ������ ������ � ��������� ��������� ��������, ������ - 
-- ���������� �� ������� ������ ������. ����� ���������� 2 ������� � ������ ��������� �������, ����������� ������� ����� ���������� ������ ������ ������ � ������ ������.
-- ������� ������ �� �����, ��� ������� ������ 0 (�� ���� ��������� ������ ������ ������ ���� ����, ��� ������ ������� ������)


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


-- ������� �8
-- ����� ������ �������� ��� ������ ������?
-- �����: ������ ����������� ����
-- ������ �������: ������� �������������, ��� �������� ��� ��������� ���� ���������� �������� � ������. ����� � ������� flights ������������ ������� airports �������� �� ���������� ��������
-- � �� ���������� ������, ����� ������� ���������� ������������. ����� ��� ������ ��������� except �� ���������� �������������, ���������� ������ ���� ��������� ��� ���������� 
-- ������� ������ ��� ����������, ����� �������� ���������� ��� ����������� �������. ��� ����� �������� ����� ������, ���������� ���� ����������, ����� �������� � ����� �� ��� ����������
-- � ������ �����.

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


-- ������� �9
-- ��������� ���������� ����� �����������, ���������� ������� �������, �������� � ���������� ������������ ���������� ���������  � ���������, ������������� ��� �����
-- �����: ������ ����������� ����
-- ������ �������: � ������� flights ������������ � ������� airports, ����� ���������� ������������ ���������� ������ � ��������, ����� ������������ ������� aircrafts, �����
-- ������� �������� ��������� �������� ��� ���� ��� ����� �����. �����, ��������� ������� ������� ����������, ������� ��������� ������� �� ��������� ���������� ����� �����������
-- � ��� ������ ��������� case ������� ��������, ��� ����������� ��������� ��������� ���������� ���������� � ���������� ������������ ��������� ��������.

select distinct a_departure.airport_code as departure_airport, a_departure.airport_name as departure_airport_name, a_arrival.airport_code as arrival_airport, a_arrival.airport_name as arrival_airport_name,
a_departure.longitude as departure_longitude, a_departure.latitude as departure_latitude, a_arrival.longitude as arrival_longitude, a_arrival.latitude as arrival_latitude,
sind(a_departure.latitude) * sind(a_arrival.latitude) + cosd(a_departure.longitude) * cosd(a_arrival.longitude) * cosd(a_departure.longitude - a_arrival.longitude) as distance_in_radians,
sind(a_departure.latitude) * sind(a_arrival.latitude) + cosd(a_departure.longitude) * cosd(a_arrival.longitude) * cosd(a_departure.longitude - a_arrival.longitude) * 6371 as distance_in_km,
aircrafts.range,
	case
		when aircrafts.range > sind(a_departure.latitude) * sind(a_arrival.latitude) + cosd(a_departure.longitude) * cosd(a_arrival.longitude) * cosd(a_departure.longitude - a_arrival.longitude) * 6371 then '���������� ������ ���������'
		else '���������� ������ ���������'
	end diff_with_range
from flights
join airports a_departure on flights.departure_airport = a_departure.airport_code
join airports a_arrival on flights.arrival_airport = a_arrival.airport_code 
join aircrafts on flights.aircraft_code = aircrafts.aircraft_code
	 


