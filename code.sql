{\rtf1\ansi\ansicpg1252\cocoartf1671\cocoasubrtf100
{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww10800\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 /* 1) Counts number of lines in each segment, there are two segments 30 and 87 with 1000 rows each*/\
select segment, count(segment) as 'rows per segment'\
from subscriptions group by segment;\
\
/* 2) Shows the max and min dates for subscription start and end dates, I can calculate churn rates from January 1st 2017 to March 31st 2017 */\
select \
max(subscription_start) as 'Most Recent Start', min(subscription_start) as 'Oldest Start', max(subscription_end) as 'Most Recent End', min(subscription_end) as 'Oldest End'\
from subscriptions;\
\
/* 3) created a table of start and end dates for first three months of 2017 for which codeflix can use to calculate churn */\
with months as (select\
'2017-01-01' as first_day,'2017-01-31' as last_day\
union select\
'2017-02-01' as first_day,'2017-02-28' as last_day\
union select\
'2017-03-01' as first_day,'2017-03-31' as last_day),\
\
/* 4) cross join months and subs in new table*/\
 cross_join as\
 (select * from subscriptions cross join months),\
\
/* 5) status table gives us columns to sum to calculate churn*/\
 status as (select id, first_day as month, \
case when (segment = 87) and (subscription_start < first_day) and (subscription_end > first_day or subscription_end is null) then 1 else 0 end as is_active_87, \
case when (segment = 30) and (subscription_start < first_day) and (subscription_end > first_day or subscription_end is null) then 1 else 0 end as is_active_30,\
\
/* 6) added canceled columns */\
case when (segment = 87) and (subscription_end between first_day and last_day) then 1 else 0 end as is_canceled_87,\
case when (segment = 30) and (subscription_end between first_day and last_day) then 1 else 0 end as is_canceled_30\
from cross_join),\
\
/* 7) status aggregate is the sum of each case statement column in status per month*/\
status_aggregate as (select month,\
  sum(is_active_87) as 'sum_active_87',\
  sum(is_active_30) as 'sum_active_30',\
  sum(is_canceled_87) as 'sum_canceled_87',\
  sum(is_canceled_30) as 'sum_canceled_30'\
  from status\
  group by month\
  order by month)\
\
/* 8) Calculates the churn rate*/\
select month, 1.0 * sum_canceled_87 / sum_active_87 as 'Seg87_churn', 1.0 * sum_canceled_30 / sum_active_30 as 'Seg30_churn'  \
from status_aggregate;\
\
/* 9) to support a large number of segments, add segment as a column to the status and status_aggregate table so that it can be used as an identifier when making the final query - see below: */\
\
with months as (select\
'2017-01-01' as first_day,'2017-01-31' as last_day\
union select\
'2017-02-01' as first_day,'2017-02-28' as last_day\
union select\
'2017-03-01' as first_day,'2017-03-31' as last_day),\
\
cross_join as\
 (select * from subscriptions cross join months),\
 \
status as (select id, segment, first_day as month, \
case when (subscription_start < first_day) and (subscription_end > first_day or subscription_end is null) then 1 else 0 end as is_active, \
case when (subscription_end between first_day and last_day) then 1 else 0 end as is_canceled\
from cross_join),\
\
status_aggregate as (select month, segment,\
  sum(is_active) as 'sum_active',\
  sum(is_canceled) as 'sum_canceled'\
  from status\
  group by month, segment\
  order by segment)\
select *, 1.0 * sum_canceled / sum_active as 'churn' from status_aggregate;}