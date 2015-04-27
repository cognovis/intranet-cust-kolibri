-- 
-- packages/intranet-cust-kolibri/sql/postgresql/upgrade/upgrade-4.0.3.0.3-4.0.3.0.4.sql
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

SELECT acs_log__debug('/packages/intranet-cust-kolibri/sql/postgresql/upgrade/upgrade-4.0.3.0.4-4.0.3.0.5.sql','');

-- add the processing time
create or replace function inline_0 ()
returns integer as $body$
declare
        v_count  integer;
begin
        -- Drop the old unique constraints
        select count(*) into v_count from user_tab_columns
        where lower(table_name) = 'im_projects' and lower(column_name) = 'processing_time';
        IF v_count > 0 THEN
                return 1;
        END IF;

        alter table im_projects
        add column processing_time float;

        return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();

SELECT im_dynfield_attribute_new ('im_project', 'processing_time', 'Processing Time', 'numeric', 'float', 'f', 20, 't');
update im_dynfield_layout set pos_y = '20', sort_key = '20' where attribute_id = (select attribute_id from im_dynfield_attributes where acs_attribute_id = (select attribute_id from acs_attributes where attribute_name = 'processing_time'));
update im_dynfield_attributes set also_hard_coded_p = 'f' where acs_attribute_id = (select attribute_id from acs_attributes where attribute_name = 'processing_time');