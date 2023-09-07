use pmg_assess;

/* converted date columns to datetime entities for smoother query */
select * from campaign_info;

select * from marketing_performance;

select * from website_revenue;

/* Q1. Query to get the sum of all the impressions by day */
select date, sum(impressions) as total_impressions_per_day from marketing_performance
group by date
order by date;

select dayname(date) as day_of_week, sum(impressions) as total_impressions_per_day from marketing_performance
group by dayname(date)
order by dayofweek(date);

/* Q2. query for the top 3 highest valued state */
select state, sum(revenue) as total_revenue from website_revenue
group by state
order by total_revenue desc
limit 3;

/* the third best state (Ohio) produced 37577 in revenue */

/* Q3. Write a query that shows total cost, impressions, clicks, and revenue of each campaign. Make sure to include the campaign name in the output. */
select c.name, sum(m.cost) as total_cost, sum(m.impressions) as total_impressions, sum(m.clicks) as total_clicks, sum(w.revenue) as total_revenue from campaign_info as c
left join marketing_performance as m
on c.id = m.campaign_id
left join website_revenue as w
on c.id = w.campaign_id
group by c.name;

/* Q4. Write a query to get the number of conversions of Campaign 5 by state. Which state generated the most conversions for this campaign? */
/* first make a separate column for states on marketing_performance table */

alter table marketing_performance 
add country varchar(255), 
add state varchar(255);

update marketing_performance
set 
    country = case 
		when LOCATE('-', geo) > 0 then SUBSTRING(geo, 1, LOCATE('-', geo) - 1) 
		else geo
    end,
    state = case 
		when LOCATE('-', geo) > 0 then SUBSTRING(geo, LOCATE('-', geo) + 1) 
		else NULL 
    end;

/* drop the column that is of no use now */
alter table marketing_performance
drop column geo;

/* sanity check */
select * from marketing_performance;

select c.name, sum(m.conversions) as total_conversions, m.state from campaign_info as c
left join marketing_performance as m
on c.id = m.campaign_id
where c.name like "Campaign5"
group by m.state
order by total_conversions desc;

/* the best state is Georgia for campaign5 */


/* Q5. determining the most efficient campaign */

/* based on ROI (profit = revenue - cost) */

with campaign_roi as (
select m.campaign_id, sum(m.cost) as total_cost, sum(m.impressions) as total_impressions, sum(m.clicks) as total_clicks, sum(w.revenue) as total_revenue from marketing_performance as m
left join website_revenue as w
on m.date = w.date
group by m.campaign_id)

select campaign_id, total_cost, total_revenue, (total_revenue - total_cost) as profit, ((total_revenue - total_cost)/total_cost) as ROI
from campaign_roi
order by ROI desc;

/* shows that campaign 5 did the best in efficiency for ROI */

/* for cost per acquisition */

select campaign_id, sum(cost) as total_cost, sum(conversions) as total_coversions, (sum(cost)/sum(conversions)) as CPA from marketing_performance
group by campaign_id
order by CPA ASC;

/* campaign4 is doing the best in terms of CPA */

/* After reviewing the campaigns, I believe that Campaign 4 stands out as the most effective. The primary reason for this assessment 
is its impressive performance metrics. Notably, Campaign 4 boasts the lowest CPA among all our campaigns, indicating a cost-effective customer 
acquisition. Additionally, despite its low acquisition cost, it has delivered a high ROI, which underscores its profitability.

Given these strong indicators, I recommend that we consider allocating a larger portion of our advertising budget to Campaign 4. This will allow 
us to capitalize on its demonstrated efficiency and potentially magnify our returns. As always, we'll continue to monitor its performance to 
ensure that the increased investment yields the expected results */

/* BONUS */

/* I split the date column into days and merged the two tables (marketing_performance, website_revenue) by their corresponding date and campaign_id.
I used two critierias since there were days where two campaign were online on the same days. I then grouped cost and revenue and found profit and ROI 
after joining the tables */

with comp_day_ROI as (
	select m.*, dayname(m.date) as day_of_week, sum(m.cost) as total_cost, sum(w.revenue) as total_rev from marketing_performance as m
    left join website_revenue as w
    on m.date = w.date AND m.campaign_id = w.campaign_id
    group by dayname(m.date)
    )
select day_of_week, (total_rev - total_cost) as profit, ((total_rev - total_cost)/total_cost) as ROI from comp_day_ROI
order by ROI desc;

/* shows that Wedndesday gives the best ROI */

with comp_day_CPA as (
	select m.*, dayname(m.date) as day_of_week, sum(m.cost) as total_cost, sum(m.conversions) as total_conversion from marketing_performance as m
    left join website_revenue as w
    on m.date = w.date AND m.campaign_id = w.campaign_id
    group by dayname(m.date)
    )
select day_of_week, (total_cost/total_conversion) as CPA from comp_day_CPA
order by CPA;

/* Wendesday Does the best for overall both CPA and ROI after running two tests! INVEST IN WEDNESDAY */