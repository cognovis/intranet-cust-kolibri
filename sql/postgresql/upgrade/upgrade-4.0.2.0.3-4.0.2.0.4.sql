-- 
-- packages/intranet-cust-kolibri/sql/postgresql/upgrade/upgrade-4.0.2.0.3-4.0.2.0.4.sql
-- 
-- Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2012-04-07
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-cust-kolibri/sql/postgresql/upgrade/upgrade-4.0.2.0.3-4.0.2.0.4.sql','');

update im_costs set cost_center_id = 140731 where project_id in (select project_id from im_projects where project_type_id in (10000014));
update im_costs set cost_center_id = 140733 where project_id in (select project_id from im_projects where project_type_id in (10000013,10000012,10000011));
update im_costs set cost_center_id = 140737 where project_id in (select project_id from im_projects where project_type_id in (10000099,10000126,10000127,10000128,10000098));
update im_costs set cost_center_id = 140729 where project_id in (select project_id from im_projects where project_type_id in (87,88,89,90,91,92,93,94,95,96,2500,2503));
update im_costs set cost_center_id = 140725 where project_id in (select project_id from im_projects where project_type_id in (10000097));
update im_costs set cost_center_id = 140727 where project_id in (select project_id from im_projects where project_type_id in (10000010));
update im_costs set cost_center_id = 140723 where project_id in (select project_id from im_projects where project_type_id in (10000124,10000125));
update im_costs set cost_center_id = 140725 where project_id in (select project_id from im_projects where project_type_id in (85,86));
update im_costs set cost_center_id = 12388 where project_id in (select project_id from im_projects where project_type_id in (10000007,10000015,10000016));

update im_costs set cost_type_id = 3700 where cost_type_id in (10000310,10000311,10000312,10000313,10000314,10000315,10000316);
update im_costs set cost_type_id = 3702 where cost_type_id in (10000343,10000344,10000345,10000346,10000347,10000348,10000349);
update im_costs set cost_type_id = 3704 where cost_type_id in (10000317,10000318,10000319,10000320,10000321,10000322,10000323);
update im_costs set cost_type_id = 3706 where cost_type_id in (10000336,10000337,10000338,10000339,10000340,10000341,10000342);

-- German Editing
update im_projects set project_type_id = 10000014 where project_type_id = 10000011 and source_language_id in (281,282,283);

-- other editing
update im_projects set project_type_id = 10000011 where project_type_id in (10000012,10000013);
update im_invoice_items set item_type_id = 10000011 where item_type_id in  (10000012,10000013);
update im_materials set task_type_id = 10000011 where task_type_id in  (10000012,10000013);
update im_trans_tasks set task_type_id = 10000011 where task_type_id in  (10000012,10000013);

-- Kolibri
update im_projects set project_type_id = 10000098 where project_id in (select project_id from im_projects where project_type_id in (10000099,10000126,10000127,10000128));
update im_projects set project_type_id = 10000124 where project_id in (select project_id from im_projects where project_type_id in (10000125));
update im_projects set project_type_id = 10000007 where project_id in (select project_id from im_projects where project_type_id in (10000015,10000016));

update im_invoice_items set item_type_id = 10000007 where item_type_id in (10000015,10000016);
update im_materials set task_type_id = 10000007 where task_type_id in  (10000015,10000016);
update im_trans_tasks set task_type_id = 10000007 where task_type_id in  (10000015,10000016);

update im_projects set project_type_id = 86 where project_id in (select project_id from im_projects where project_type_id in (86));

-- Update Projects Cost Centers
update im_projects set cost_center_id = 140731 where project_type_id = 10000014;
update im_projects set cost_center_id = 140733 where project_type_id = 10000011;
update im_projects set cost_center_id = 140737 where project_type_id = 10000099;
update im_projects set cost_center_id = 140729 where project_type_id in (87,88,89,90,91,92,93,94,95,96,2500,2503);
update im_projects set cost_center_id = 140725 where project_type_id = 10000097;
update im_projects set cost_center_id = 140727 where project_type_id = 10000010;
update im_projects set cost_center_id = 140723 where project_type_id = 10000124;
update im_projects set cost_center_id = 140725 where project_type_id = 86;
update im_projects set cost_center_id = 12388 where project_type_id = 10000007;
