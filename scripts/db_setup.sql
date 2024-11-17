USE [cw-data-mssql-db]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* CREATE APPLICATION TABLE */
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'BUCKET_LIST_ITEMS' AND TABLE_SCHEMA = 'dbo')
	DROP TABLE [dbo].[BUCKET_LIST_ITEMS] 

CREATE TABLE [dbo].[BUCKET_LIST_ITEMS](
	[id] [int] NOT NULL,
	[description] [nvarchar](100) NOT NULL,
	[completed] [bit] NOT NULL,
 CONSTRAINT [PK_BUCKET_LIST_ITEMS] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/* LOAD DATA */
INSERT INTO [dbo].[BUCKET_LIST_ITEMS]
           ([id]
           ,[description]
           ,[completed])
     VALUES
		(1	, N'Travelling the world on a unicycle 🌍', 0 ),
		(2	, N'Watching all +1000 episodes of One Piece 📺', 0 ),
		(3	, N'Skiing without dying in the process ⛷️', 1 ),
		(4	, N'Dyeing my hair rainbow and visiting my grandma 🌈', 0 ),
		(5	, N'Becoming a cloud master ☁️', 0 ),
		(6	, N'Attempting synchronized swimming with rubber ducks 🦆', 0 ),
		(7	, N'Organizing a bubble wrap popping symphony orchestra 🎶', 1 ),
		(8	, N'Winning a "Who Can Wear the Most Hats" fashion competition 🎩', 1 ),
		(9	, N'Going to the office dressed up as a hot dog 🌭', 1 ),
		(10	, N'Not spending all my salary on Genshin Impact 💸', 0 ),
		(11	, N'Setting the record for the most people doing the Macarena on pogo sticks 💃', 1 ),
		(12	, N'Hosting a "Lip Sync Battle for Pets" contest 🐶', 0 ),
		(13	, N'Becoming the best at zero_gravity dinosaur yoga 🧘‍♂', 1 ),
		(14	, N'Singing karaoke while eating a pasta bowl 🎤', 0 ),
		(15	, N'Using ChatGPT to generate these ideas because I am lazy 🧠', 1 )
GO


