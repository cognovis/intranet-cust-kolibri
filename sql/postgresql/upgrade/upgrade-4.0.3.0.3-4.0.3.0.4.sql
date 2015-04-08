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

SELECT acs_log__debug('/packages/intranet-cust-kolibri/sql/postgresql/upgrade/upgrade-4.0.3.0.3-4.0.3.0.4.sql','');

select im_component_plugin__del_module('intranet-trans-project-wizard');
select im_menu__del_module('intranet-trans-project-wizard');

-- Fix for wrong metainformation of previous version
select im_component_plugin__del_module('intranet-intranet-trans-project-wizard');
select im_menu__del_module('intranet-intranet-trans-project-wizard');

select apm_package__delete(84198);


SELECT im_component_plugin__new (
    null,					-- plugin_id
    'acs_object',				-- object_type
    now(),					-- creation_date
    null,					-- creation_user
    null,					-- creation_ip
    null,					-- context_id
    'Project Translation Wizard',		-- plugin_name
    'intranet-cust-kolibri',	-- package_name
    'left',					-- location
    '/intranet/projects/view',		-- page_url
    null,					-- view_name
    -10,					-- sort_order
    'kolibri_trans_project_component -project_id $project_id',
    'lang::message::lookup "" intranet-cust-kolibri.Translation_Project_Wizard "Translation Project Wizard"'
);