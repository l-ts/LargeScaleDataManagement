-- TSOLAS LEONIDAS

-- 1st Assignment

--Part 1

--Question P1a

create view p1_a as
select
cmp.name,
price_amount
from
companies cmp
left join acquisitions acq
    on acq.company_name = cmp.name
    and acq.company_city = cmp.city
where status = 'acquired';

--select * from p1_a;

--Question P1b

create view p1_b as
select
count(1) as num_of_cmp
from
companies cmp
where founded_at between '2011-01-01' and '2014-12-31';

--select * from p1_b;

--Question P1_c

create view p1_c as
with
temp_state_num -- contains (state_code , number of Security startups per state)
as
(
select
state_code,
count(1) as state_num
from
companies
where
    category_list like '%Security%'
    and state_code is not null
group by state_code
),
max_state -- select max(number of Security startups per state) from previous cte
as
(
select
max(state_num) as max_state_num
from temp_state_num
)
select
state_code,
state_num
from
temp_state_num tsn
inner join max_state ms on ms.max_state_num = tsn.state_num -- select those that have num = max(num)
where state_num = max_state_num;

--select * from p1_c;

--Question P1_d

create view p1_d as
with
k1 -- contains (city , number of startups in city)
as
(
select
city,
count(distinct name) as num_of_startups
from
companies
where city is not null 
group by city
),
k2 -- contains (acquirer_city , acquirer_name in acquirer_city)
as
(
select
acquirer_city,
count(distinct acquirer_name) as num_of_acquirers
from
acquisitions
where acquirer_city is not null and acquirer_name is not null
group by acquirer_city
),
k3
as
(
select
acquirer_city,
coalesce(num_of_startups,0) num_of_startups,
coalesce(num_of_acquirers,0) num_of_acquirers
from k2
left join k1 
    on acquirer_city = city
)
select
acquirer_city
from 
k3 
where num_of_startups < num_of_acquirers;

--select * from p1_d

--Part 2

--p2_a

CREATE TABLE AT(i INT NOT NULL, j INT NOT NULL, val INT,CONSTRAINT AT_PK PRIMARY KEY (i,j ) );

insert into AT (i,j,val)
select j,i,val
from A;

create view p2_a as
select
i,
j,
val
from AT
order by i,j;

--select * from p2_a;

--Question p2_b

create view p2_b as
select
sum(B.val * A.val) as dot_1
from A
inner join B
    on B.i = A.i and B.j = 2
where A.j = 1;

--select * from p2_b;

--Question p2_c

create view p2_c as
select
sum(B.val * A.val) as dot_2
from A
inner join B
    on B.i = A.j and B.j = 2
where A.i = 1;

--select * from p2_c;

--Question p2_d

create view p2_d as
select A.i,
   B.j,
   sum(A.val * B.val) AS val
from A
inner join B
on A.j = B.i
group by A.i, B.j
order by a.i , b.j;

--select * from p2_d;

--Part 3

create view p3_a as
with recursive paths AS
(
SELECT
a,
b,
d,
a || ' -> ' || b as c,
1 as depth
from
streets
where
a = 'AUEB'
union
select
str.a,
str.b,
str.d + p.d as d,
c || ' -> ' || str.b as c,
depth + 1 as depth
from
streets str
inner join paths p ON p.b = str.a
where depth < 4 and str.d + p.d <= 11
) select
b as company_name,
d as distance
--,depth as num_of_moves
--,c as path
from
paths;

--select * from p3_a

--Question p3_b

create view p3_b as
with recursive paths_b AS
(
SELECT
a as starting_node,
a,
b,
d,
a || ' -> ' || b as c,
1 as depth
from
streets
union
select
starting_node,
str.a,
str.b,
str.d + p.d as d,
c || ' -> ' || str.b as c,
depth + 1 as depth
from
streets str
inner join paths_b p ON p.b = str.a
where depth < 4 and str.d + p.d <= 14
),
temp_set
as
(
select
starting_node,
b as company_name,
d as distance
--,depth as num_of_moves
,c as path
from
paths_b
where
starting_node <> b
and c like '%AUEB%'
and (starting_node <> 'AUEB' or b <> 'AUEB')
),
final_set
as
(
select
case
    when a.company_name = b.starting_node then a.path || ' ### ' || b.path
    when b.company_name = a.starting_node then b.path || ' ### ' || a.path
end as path,   
case
    when a.company_name = b.starting_node then a.starting_node
    when b.company_name = a.starting_node then b.starting_node
end as starting_node,
case
    when a.company_name = b.starting_node then b.company_name
    when b.company_name = a.starting_node then a.company_name
end as final_node,
b.distance + a.distance as total_distance
from
temp_set a
inner join temp_set b
    on (b.company_name = a.starting_node or a.company_name = b.starting_node)
    and b.distance + a.distance <= 14
)
select 
starting_node,
final_node,
total_distance 
from final_set 
where starting_node <> final_node
group by starting_node,final_node,total_distance;

--select * from p3_b

-- Question p3_c
drop table if exists streets2;

create table streets2(id INT, direction CHAR(1), A VARCHAR(255), B VARCHAR(255), d INT, PRIMARY KEY (id, direction));
insert into streets2 select * from streets;

with recursive paths_c AS
(
SELECT
a,
b,
a || ' -> ' || b as c,
1 as depth
from
streets
union
select
str.a,
str.b,
c || ' -> ' || str.b ||  ' -> ' || str_cycle.a as c,
depth + 1 as depth
from
streets str
inner join paths_c p ON p.b = str.a and str.b <> p.a -- avoid cycles with length 1 
inner join streets str_cycle on str.b = str_cycle.a and str_cycle.b = p.a 
where depth<3
),
rows_to_del
as
(
select 
a,
b
from paths_c  
where depth = 3 limit 1  -- get only one pair to delete    
)
delete 
from streets2 
	using rows_to_del rtd
where  
    (streets2.a = rtd.a and streets2.b = rtd.b)
    or
    (streets2.b = rtd.a and streets2.a = rtd.b)

-- Since there was found only one cycle of length 3, there are 3 edges that formulate this cycle. 
-- No matter which one of these 3 edges we cut, the graph will continue to be a tree, since each and 
-- every one of these edges will still be connected, while the rest graph will not be affected.


-- Check which records has been deleted from streets2
create view p3_c as
select * from streets except select * from streets2;

-- select * from p3_c;

-- run previoues recursion function for streets2 to return cycles - if any exist
with recursive paths_c AS
(
SELECT
a,
b,
a || ' -> ' || b as c,
1 as depth
from
streets2
union
select
str.a,
str.b,
c || ' -> ' || str.b ||  ' -> ' || str_cycle.a as c,
depth + 1 as depth
from
streets2 str
inner join paths_c p ON p.b = str.a and str.b <> p.a
inner join streets2 str_cycle on str.b = str_cycle.a and str_cycle.b = p.a 
where depth<3
)
select 
*
from paths_c  
where depth = 3 limit 1  
-- The query returned 0 results, so there are no cycles in our graph.

-- Question p3_d

create view p3_d as
with
recursive paths_d
as
(
select
a as starting_node,
a,
b,
d as distance,
a || '->' || b as pth,
cast(null as character varying) as lag_node,
1 as depth
from streets
union
select
rpd.starting_node as starting_node,
str.a,
str.b,
rpd.distance + str.d as distance,
pth || '->' || str.b as pth,
rpd.a as lag_node,
depth + 1 as depth
from streets str
inner join paths_d rpd  
     on str.a = rpd.b 
     and str.b <> coalesce(rpd.a,'') -- avoid cycles of length 2
     and str.b <> coalesce(rpd.lag_node,'')  --  avoid cycles of length 3
where depth < (select count(distinct a) from streets) 
-- a tree with n nodes has at most n-1 edges, so depth of search must be n-1 in worst case
),
final
as
(
select 
starting_node
,b 
,distance 
,pth
,rank() over (order by distance desc) as RNK
from
paths_d
) 
select 
starting_node
,b 
,distance
--,pth
from 
final
where RNK = 1
limit 1; -- since we ensured there is only one pair with maximum distance

-- select * from p1_d