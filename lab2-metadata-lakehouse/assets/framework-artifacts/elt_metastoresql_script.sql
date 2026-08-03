CREATE SCHEMA [mtd]
GO

CREATE TABLE [mtd].[enrich_control](
	[control_id] [int] IDENTITY(1,1) NOT NULL,
	[source_item_name] [varchar](200) NOT NULL,
	[source_type] [varchar](100) NOT NULL,
	[source_format] [varchar](100) NOT NULL,
	[target_item_name] [varchar](200) NULL,
	[target_type] [varchar](100) NOT NULL,
	[target_format] [varchar](100) NOT NULL,
	[load_type] [varchar](100) NOT NULL,
	[transformation_flag] [int] NOT NULL,
	[enable_flag] [int] NOT NULL,
	[system_timestamp] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_enrich_control] PRIMARY KEY CLUSTERED 
(
	[control_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [mtd].[enrich_control] ADD  DEFAULT ((0)) FOR [transformation_flag]
GO

ALTER TABLE [mtd].[enrich_control] ADD  DEFAULT ((1)) FOR [enable_flag]
GO

ALTER TABLE [mtd].[enrich_control] ADD  DEFAULT (sysdatetime()) FOR [system_timestamp]
GO

CREATE TABLE [mtd].[enrich_audit](
	[run_id] [varchar](255) NOT NULL,
	[control_id] [int] NOT NULL,
	[event_type] [varchar](50) NULL,
	[rows_affected] [bigint] NULL,
	[event_status] [varchar](255) NULL,
	[event_start_time] [datetime2](7) NOT NULL,
	[event_end_time] [datetime2](7) NULL,
	[error_details] [varchar](max) NULL,
	[event_triggered_by] [varchar](255) NULL,
	[spark_monitoring_url] [varchar](max) NULL,
	[notebook_run_snapshot] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO



CREATE TABLE [mtd].[serve_control](
	[control_id] [int] IDENTITY(1,1) NOT NULL,
	[source_item_name] [varchar](200) NOT NULL,
	[source_type] [varchar](100) NOT NULL,
	[source_format] [varchar](100) NOT NULL,
	[target_item_name] [varchar](200) NULL,
	[target_type] [varchar](100) NOT NULL,
	[target_format] [varchar](100) NOT NULL,
	[load_type] [varchar](100) NOT NULL,
	[transformation_flag] [int] NOT NULL,
	[enable_flag] [bit] NOT NULL,
	[system_timestamp] [datetime2](7) NOT NULL
) ON [PRIMARY]
GO

ALTER TABLE [mtd].[serve_control] ADD  DEFAULT ((0)) FOR [transformation_flag]
GO

ALTER TABLE [mtd].[serve_control] ADD  DEFAULT ((1)) FOR [enable_flag]
GO

ALTER TABLE [mtd].[serve_control] ADD  DEFAULT (sysdatetime()) FOR [system_timestamp]
GO




CREATE TABLE [mtd].[serve_audit](
	[run_id] [varchar](max) NOT NULL,
	[control_id] [int] NOT NULL,
	[event_type] [varchar](100) NULL,
	[rows_affected] [bigint] NULL,
	[event_status] [varchar](100) NULL,
	[event_start_time] [datetime2](7) NULL,
	[event_end_time] [datetime2](7) NULL,
	[error_details] [varchar](max) NULL,
	[event_triggered_by] [varchar](100) NULL,
	[spark_monitoring_url] [varchar](max) NULL,
	[notebook_run_snapshot] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO





CREATE TABLE [mtd].[transformation_config](
	[transformation_id] [int] IDENTITY(1,1) NOT NULL,
	[control_id] [int] NOT NULL,
	[process_stage] [varchar](50) NOT NULL,
	[source_item_name] [varchar](255) NOT NULL,
	[source_column_name] [varchar](255) NULL,
	[source_column_datatype] [varchar](255) NULL,
	[target_item_name] [varchar](255) NOT NULL,
	[target_column_name] [varchar](255) NULL,
	[target_column_datatype] [varchar](255) NULL,
	[transformation_type] [varchar](50) NOT NULL,
	[transformation_rule] [varchar](max) NULL,
	[transformation_rule_criteria] [varchar](max) NULL,
	[transformation_description] [varchar](max) NULL,
	[transformation_order] [int] NULL,
	[enable_flag] [bit] NOT NULL,
	[created_at] [datetime2](7) NULL,
	[updated_at] [datetime2](7) NULL,
	[updated_by] [varchar](255) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[transformation_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [mtd].[transformation_config] ADD  DEFAULT ((1)) FOR [transformation_order]
GO

ALTER TABLE [mtd].[transformation_config] ADD  DEFAULT ((1)) FOR [enable_flag]
GO

ALTER TABLE [mtd].[transformation_config] ADD  DEFAULT (getdate()) FOR [created_at]
GO

ALTER TABLE [mtd].[transformation_config] ADD  DEFAULT (getdate()) FOR [updated_at]
GO




CREATE TABLE [mtd].[dq_config](
	[dq_rule_id] [int] IDENTITY(1,1) NOT NULL,
	[control_id] [int] NOT NULL,
	[process_stage] [varchar](50) NOT NULL,
	[dataset_name] [varchar](255) NULL,
	[dq_rule] [nvarchar](255) NULL,
	[dq_rule_criteria] [nvarchar](max) NULL,
	[dq_rule_criteria_additional] [nvarchar](max) NULL,
	[enable_flag] [bit] NOT NULL,
	[system_timestamp] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[dq_rule_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [mtd].[dq_config] ADD  DEFAULT ((1)) FOR [enable_flag]
GO

ALTER TABLE [mtd].[dq_config] ADD  DEFAULT (sysdatetime()) FOR [system_timestamp]
GO


CREATE TABLE [mtd].[dq_results](
	[dq_result_id] [int] IDENTITY(1,1) NOT NULL,
	[dq_rule_id] [int] NOT NULL,
	[control_id] [int] NOT NULL,
	[process_stage] [varchar](50) NOT NULL,
	[dataset_name] [nvarchar](100) NULL,
	[dq_rule] [nvarchar](100) NULL,
	[dq_status] [nvarchar](100) NULL,
	[dq_result] [nvarchar](100) NULL,
	[dq_additional_details] [nvarchar](max) NULL,
	[recs_passed] [int] NULL,
	[recs_failed] [int] NULL,
	[total_recs] [int] NULL,
	[dq_rule_criteria] [nvarchar](max) NULL,
	[dq_rule_criteria_additional] [nvarchar](max) NULL,
	[dq_timestamp] [datetime2](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[dq_result_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [mtd].[dq_results] ADD  DEFAULT (getdate()) FOR [dq_timestamp]
GO



CREATE TABLE [mtd].[shortcut_audit](
	[shortcut_name] [varchar](100) NOT NULL,
	[shortcut_path] [varchar](200) NOT NULL,
	[source_type] [varchar](100) NULL,
	[source_workspace_id] [varchar](100) NULL,
	[source_workspace_name] [varchar](100) NULL,
	[source_item_id] [varchar](100) NULL,
	[source_item_name] [varchar](100) NULL,
	[source_item_type] [varchar](100) NULL,
	[onelake_path] [varchar](200) NULL,
	[connection_id] [varchar](200) NULL,
	[location] [varchar](200) NULL,
	[bucket] [varchar](200) NULL,
	[subpath] [varchar](200) NULL,
	[medallion_layer] [varchar](50) NULL,
	[lakehouse_display_name] [varchar](200) NULL,
	[shortcut_audit_refresh_time] [datetime2](6) NULL
) ON [PRIMARY]
GO


CREATE TABLE [mtd].[mirroring_audit](
	[displayName_name] [varchar](100) NOT NULL,
	[description] [varchar](500) NOT NULL,
	[type] [varchar](50) NULL,
	[oneLakeTablesPath] [varchar](500) NULL,
	[sourceSchemaName] [varchar](100) NULL,
	[sourceTableName] [varchar](100) NULL,
	[status] [varchar](50) NOT NULL,
	[processedBytes] [int] NULL,
	[lastSyncDateTime] [datetime2](6) NULL,
	[mirroring_audit_refresh_time] [datetime2](6) NULL
) ON [PRIMARY]
GO