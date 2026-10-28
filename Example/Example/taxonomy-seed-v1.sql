-- NavigationSplitStack example taxonomy seed, version 1.
-- Data only: apply after creating taxa and species, inside a transaction.
-- Source: taxonomy.json; intermediate order nodes are omitted.
-- Additional cats: https://www.catsg.org/cats/livingspecies
-- Example labels are preserved; this is not an authoritative taxonomy.
-- Fixed UUIDs make navigation destinations stable across fresh databases.
-- Reapplying updates seeded rows without replacing parents or deleting other rows.
-- No schema, transaction statements, PRAGMAs, or migration-history records.
-- Contents: 29 taxa (4 classes, 25 families), 94 species.
-- Empty family: Hedgehogs (Erinaceidae). Long family: Cats (Felidae), 41 species.

-- Classes, followed by families (parents precede children).
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('3DACCF5A-C7D8-537D-ADAD-D57A9E815EF7', NULL, 'Amphibians')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('2D55811A-8732-59B9-8D25-DA42DC94D392', NULL, 'Birds')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('295A514B-96BB-5832-B1A8-023317E8861C', NULL, 'Mammals')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('25B624F5-1B3E-575B-88D0-B7A7237D7FBB', NULL, 'Reptiles')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('05B9D83E-ADF3-52CE-87F7-60E505E75ECA', '25B624F5-1B3E-575B-88D0-B7A7237D7FBB', 'Alligators (Alligatoridae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('B298CD51-646D-5ABC-98CC-41469D89A5B1', '2D55811A-8732-59B9-8D25-DA42DC94D392', 'Barn owls (Tytonidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('7ABB3F07-5D78-5D31-8138-A8D3E70AF300', '295A514B-96BB-5832-B1A8-023317E8861C', 'Bears (Ursidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('ADA89CE5-9B4C-571E-80BD-054887CEE842', '295A514B-96BB-5832-B1A8-023317E8861C', 'Cats (Felidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('C315A3BF-C94A-57FB-AD5C-0311ACE82930', '25B624F5-1B3E-575B-88D0-B7A7237D7FBB', 'Chameleons (Chamaeleonidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('6172FB8F-0E3A-5207-B4CC-39F1E3AE5AEB', '2D55811A-8732-59B9-8D25-DA42DC94D392', 'Cockatoos (Cacatuidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('C4DA8948-775E-5D6E-8DF7-74EA743ADA4A', '25B624F5-1B3E-575B-88D0-B7A7237D7FBB', 'Crocodiles (Crocodylidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('316653E6-67C5-5741-8F79-3441BAE07654', '295A514B-96BB-5832-B1A8-023317E8861C', 'Deer (Cervidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('B7E13901-6AAA-551A-A873-C3EA78EDBE02', '295A514B-96BB-5832-B1A8-023317E8861C', 'Dogs (Canidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('07F33225-37E0-5476-8F44-E3343BD7BF81', '295A514B-96BB-5832-B1A8-023317E8861C', 'Gibbons (Hylobatidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('0003393E-99A1-5CAA-A746-99CFE7197915', '295A514B-96BB-5832-B1A8-023317E8861C', 'Giraffids (Giraffidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('F2AD9F3C-2FD4-5F8C-836B-E747A3AA940D', '295A514B-96BB-5832-B1A8-023317E8861C', 'Great apes (Hominidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('FC8D3BF8-C7B1-5568-8D16-AD6B9B2AAE0A', '295A514B-96BB-5832-B1A8-023317E8861C', 'Hedgehogs (Erinaceidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('C8EEEF5A-2033-58F3-9016-7344D9214DDE', '25B624F5-1B3E-575B-88D0-B7A7237D7FBB', 'Iguanas (Iguanidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('FEE85747-B538-536C-8F21-13F11BA2EC93', '3DACCF5A-C7D8-537D-ADAD-D57A9E815EF7', 'Mole salamanders (Ambystomatidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('D0BDB476-DF18-5EB0-B507-8E6B2FC16E27', '2D55811A-8732-59B9-8D25-DA42DC94D392', 'Penguins (Spheniscidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('ED8DA9AD-0D66-5B7A-844B-8F20E6EC8606', '3DACCF5A-C7D8-537D-ADAD-D57A9E815EF7', 'Poison dart frogs (Dendrobatidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('ABF2605D-4E7B-505C-868D-21DB6A4A9486', '25B624F5-1B3E-575B-88D0-B7A7237D7FBB', 'Pythons (Pythonidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('58A18B9F-C707-50B7-855E-CCFF99EB74E1', '25B624F5-1B3E-575B-88D0-B7A7237D7FBB', 'Sea turtles (Cheloniidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('1ABBC20B-DE87-558F-8754-8A2A2C99C8D1', '25B624F5-1B3E-575B-88D0-B7A7237D7FBB', 'Tortoises (Testudinidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('C4109A3A-0BA2-5D27-AE5F-2B047A43294A', '3DACCF5A-C7D8-537D-ADAD-D57A9E815EF7', 'True frogs (Ranidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('ADD773CD-FBA2-5378-A890-08CEC0C190BB', '2D55811A-8732-59B9-8D25-DA42DC94D392', 'True owls (Strigidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('4D5D516D-70F3-5193-B3D7-E1C9017B6911', '2D55811A-8732-59B9-8D25-DA42DC94D392', 'True parrots (Psittacidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('BBC766C5-11ED-5F62-9636-5251233B9EEC', '3DACCF5A-C7D8-537D-ADAD-D57A9E815EF7', 'True salamanders (Salamandridae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";
INSERT INTO "taxa" ("id", "parentID", "name")
VALUES ('DD9DEAA8-386C-503C-9916-460777D2627C', '3DACCF5A-C7D8-537D-ADAD-D57A9E815EF7', 'True toads (Bufonidae)')
ON CONFLICT("id") DO UPDATE SET "parentID" = excluded."parentID", "name" = excluded."name";

-- Species; icons are separate from display names.
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('3BACF1A7-8395-5E5E-9A01-10CB3A9CC355', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Tiger', '🐅')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('5DF91682-FC53-5E30-A233-FF6699A46471', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Lion', '🦁')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('013C53D3-8583-5A5A-A003-67E9BFD0BADA', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Leopard', '🐆')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('619DAE6A-E83D-5D02-90BD-456E74C6ABC7', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Domestic cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('2EFF6916-EB81-5A7B-83A7-BDEC2633B59F', 'B7E13901-6AAA-551A-A873-C3EA78EDBE02', 'Gray wolf', '🐺')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('DCDBA074-C98B-57E3-B49B-EAC1B5AF7BB2', 'B7E13901-6AAA-551A-A873-C3EA78EDBE02', 'Red fox', '🦊')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('33BFA3B4-A446-551B-B883-94DA243FA57F', 'B7E13901-6AAA-551A-A873-C3EA78EDBE02', 'Domestic dog', '🐕')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('877DCD7B-A94F-5CB2-AB14-5CD4A5A84691', '7ABB3F07-5D78-5D31-8138-A8D3E70AF300', 'Brown bear', '🐻')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('8C7FD1B4-C0E8-5EBA-9709-6F733043349A', '7ABB3F07-5D78-5D31-8138-A8D3E70AF300', 'Polar bear', '🐻‍❄️')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('63DAEAD0-2E2C-5D17-9108-7BAB67E124E3', '7ABB3F07-5D78-5D31-8138-A8D3E70AF300', 'Giant panda', '🐼')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('6B3D7C8A-D42F-587C-9367-454D0C976503', 'F2AD9F3C-2FD4-5F8C-836B-E747A3AA940D', 'Gorilla', '🦍')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('602FA45C-F2A3-504D-827B-18AA43D2BDA0', 'F2AD9F3C-2FD4-5F8C-836B-E747A3AA940D', 'Chimpanzee', '🐵')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('2BA5AB84-6B6C-5E63-AC68-F7ED3D9D8D34', 'F2AD9F3C-2FD4-5F8C-836B-E747A3AA940D', 'Orangutan', '🦧')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('44C0396B-4F3F-513C-84BC-87499F0545F2', '07F33225-37E0-5476-8F44-E3343BD7BF81', 'Lar gibbon', '🐒')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('A06A463F-BE4A-5415-821F-5E34142B10F8', '07F33225-37E0-5476-8F44-E3343BD7BF81', 'Siamang', '🐒')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('DDD3F2E9-BE6F-53FA-8F3F-05D6CCB55BFA', '316653E6-67C5-5741-8F79-3441BAE07654', 'Moose', '🫎')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('9C6E900A-D115-5E93-B5DB-63C49DD74586', '316653E6-67C5-5741-8F79-3441BAE07654', 'Red deer', '🦌')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('B49E43DF-4D05-5DDD-96F3-102F840FE650', '316653E6-67C5-5741-8F79-3441BAE07654', 'Reindeer', '🦌')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('FDD5B5DD-1D6C-53E6-A556-B3B3346A5445', '0003393E-99A1-5CAA-A746-99CFE7197915', 'Giraffe', '🦒')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('AC152B8D-6D50-57F3-BFD0-38F6355882F2', '0003393E-99A1-5CAA-A746-99CFE7197915', 'Okapi', '🦒')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('00E08FD3-2B12-5B8F-B989-5396ED1A2C3A', '4D5D516D-70F3-5193-B3D7-E1C9017B6911', 'Scarlet macaw', '🦜')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('B64B92CE-D950-5262-A2D4-B30BDC77FEA4', '4D5D516D-70F3-5193-B3D7-E1C9017B6911', 'African grey parrot', '🦜')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('288D91FE-5602-59FA-88B6-573A13256D12', '4D5D516D-70F3-5193-B3D7-E1C9017B6911', 'Blue-and-yellow macaw', '🦜')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('FC88018F-BD95-5A2F-9CA8-8368F9BD03E9', '6172FB8F-0E3A-5207-B4CC-39F1E3AE5AEB', 'Sulphur-crested cockatoo', '🦜')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('B03323E7-64FC-5513-B0C6-B4908F642C89', '6172FB8F-0E3A-5207-B4CC-39F1E3AE5AEB', 'Galah', '🦜')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('B93EC845-87DE-5F19-81DB-CE8BD3E3845C', 'ADD773CD-FBA2-5378-A890-08CEC0C190BB', 'Great horned owl', '🦉')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('FB998721-64B0-58AA-92A9-2FAC59E3D5AE', 'ADD773CD-FBA2-5378-A890-08CEC0C190BB', 'Snowy owl', '🦉')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('DE936AFE-5C1A-534D-B63E-9FE6DF3848CB', 'ADD773CD-FBA2-5378-A890-08CEC0C190BB', 'Eurasian eagle-owl', '🦉')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('23E9DDED-7726-5DA4-B176-DC6E96FBFD32', 'B298CD51-646D-5ABC-98CC-41469D89A5B1', 'Western barn owl', '🦉')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('7108A7B1-D93D-58C9-9BE2-0E1E66B52994', 'B298CD51-646D-5ABC-98CC-41469D89A5B1', 'Eastern grass owl', '🦉')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('558256FC-0613-530F-B5FA-F206B51014A2', 'D0BDB476-DF18-5EB0-B507-8E6B2FC16E27', 'Emperor penguin', '🐧')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('A2B05832-A8A6-5A87-9E2C-0B5EAD592DF4', 'D0BDB476-DF18-5EB0-B507-8E6B2FC16E27', 'King penguin', '🐧')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('307D8E74-680C-5ED6-913F-8EEA2B8F8260', 'D0BDB476-DF18-5EB0-B507-8E6B2FC16E27', 'Little penguin', '🐧')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('AFB3714F-9DF7-517F-B65C-3AE29D012C8B', 'ABF2605D-4E7B-505C-868D-21DB6A4A9486', 'Ball python', '🐍')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('0D73595E-18B3-5094-AED2-112B29B982DB', 'ABF2605D-4E7B-505C-868D-21DB6A4A9486', 'Reticulated python', '🐍')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('9C84A109-EAB5-5964-8E9F-A07F3CB9B88D', 'C315A3BF-C94A-57FB-AD5C-0311ACE82930', 'Panther chameleon', '🦎')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('FF70524B-EAB5-5BCF-A071-1ACADB8F681E', 'C315A3BF-C94A-57FB-AD5C-0311ACE82930', 'Veiled chameleon', '🦎')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('A7E9A439-0603-55B6-B8B3-E3B7F4D0DC4B', 'C8EEEF5A-2033-58F3-9016-7344D9214DDE', 'Green iguana', '🦎')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('13C92D77-62D2-575C-8B9F-8CCBBE2736A7', 'C8EEEF5A-2033-58F3-9016-7344D9214DDE', 'Lesser Antillean iguana', '🦎')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('CDA1FFDD-04FA-5BAD-887C-A6A9B5C50FE8', '58A18B9F-C707-50B7-855E-CCFF99EB74E1', 'Green sea turtle', '🐢')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('DE0B2ADB-2CAE-5A27-B272-7350B1F17532', '58A18B9F-C707-50B7-855E-CCFF99EB74E1', 'Loggerhead sea turtle', '🐢')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('4DFA61BD-91C4-52AB-8FBE-8486916E78C4', '1ABBC20B-DE87-558F-8754-8A2A2C99C8D1', 'Galápagos giant tortoise', '🐢')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('98F34FD5-0F61-52BD-A09E-1E1D2F1051D1', '1ABBC20B-DE87-558F-8754-8A2A2C99C8D1', 'Leopard tortoise', '🐢')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('91D8F131-2F6F-5AB9-BA5D-9ADE7E54130D', 'C4DA8948-775E-5D6E-8DF7-74EA743ADA4A', 'Nile crocodile', '🐊')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('A59C6D8E-815B-504F-BF70-C282979C19FF', 'C4DA8948-775E-5D6E-8DF7-74EA743ADA4A', 'Saltwater crocodile', '🐊')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('84E0A889-A1D5-585F-8213-3F65183973F5', '05B9D83E-ADF3-52CE-87F7-60E505E75ECA', 'American alligator', '🐊')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('2B4CE6CD-98F7-5842-9875-0183BE8B602B', '05B9D83E-ADF3-52CE-87F7-60E505E75ECA', 'Chinese alligator', '🐊')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('898EADAB-EE00-509D-BFAE-45F0A3DC938A', 'C4109A3A-0BA2-5D27-AE5F-2B047A43294A', 'American bullfrog', '🐸')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('95EF236A-9C84-58DB-A6EB-102F91097B7F', 'C4109A3A-0BA2-5D27-AE5F-2B047A43294A', 'Northern leopard frog', '🐸')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('31646D9C-2B82-5267-B40E-23EA7502AD35', 'DD9DEAA8-386C-503C-9916-460777D2627C', 'Common toad', '🐸')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('FE4A0E9A-33E2-5BC5-AB18-E0702DA46C99', 'DD9DEAA8-386C-503C-9916-460777D2627C', 'Cane toad', '🐸')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('077C5CE4-FD38-5EFD-A7C3-AD3EC2030EC8', 'ED8DA9AD-0D66-5B7A-844B-8F20E6EC8606', 'Golden poison frog', '🐸')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('DD2907F5-0CFF-512F-99A7-BE4289AFA4D2', 'ED8DA9AD-0D66-5B7A-844B-8F20E6EC8606', 'Blue poison dart frog', '🐸')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('6114D8EA-3196-5246-9909-07395BEB1FC8', 'FEE85747-B538-536C-8F21-13F11BA2EC93', 'Axolotl', '🦎')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('F857D793-B640-59D9-BB19-FD22AA68EA42', 'FEE85747-B538-536C-8F21-13F11BA2EC93', 'Tiger salamander', '🦎')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('C58ABB51-2D07-5B0A-B4CE-A39C5CB68CBF', 'BBC766C5-11ED-5F62-9636-5251233B9EEC', 'Fire salamander', '🦎')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('3CCA6224-8359-5AF6-93B2-A19D78F512A9', 'BBC766C5-11ED-5F62-9636-5251233B9EEC', 'Great crested newt', '🦎')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('2DDBD4DF-8960-5535-937B-29802A14F889', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Sunda clouded leopard', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('A0B2B72A-BBF1-5514-9901-CD8AD199A31E', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Clouded leopard', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('75744C01-212B-5454-935A-BE1E368335FB', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Snow leopard', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('5B5AB6A9-3628-5389-B1F4-CEB88857407D', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Jaguar', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('25FD7175-69E0-54F5-BF88-B77FE161237B', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Serval', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('D9BAAEB9-F04D-5103-95E7-C18B5E64F6CC', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'African golden cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('6395A682-43E4-50F4-AAC4-CA8F6BBF36E8', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Caracal', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('29209C8A-8F57-57F1-A3FC-B59BB423D149', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Andean mountain cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('5E241BBF-772F-56F9-8713-78E7E16EB5E5', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Ocelot', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('5E5E3ACB-2B24-53AC-974D-4B78C0538DB3', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Margay', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('5A8BC4D5-0AD9-52C2-9D34-2229237A0AAB', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Pampas cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('1B1D3AA5-053E-582A-93B2-13B87FD7867A', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Northern tiger cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('2BB7094B-9A8E-526D-981A-6FEA84763429', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Southern tiger cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('797E12A5-1058-58C8-A1E6-6DC9E19A1CDD', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Geoffroy''s cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('2392EA58-73E5-5C0E-82BA-D2CB276E18DD', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Kodkod', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('DC39240F-9BB2-50ED-A30E-C6A5132939AA', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Marbled cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('C768FA91-B4F1-5E18-A908-6305278AD687', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Bornean bay cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('2632F59B-C39E-5294-9FF3-2CF268CF6F2C', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Asian golden cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('B77FFDB8-D17E-52FD-B05C-2481DF508D34', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Bobcat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('C5C2C289-B985-5D19-B7A9-D66EA3F71A0A', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Canada lynx', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('FDFD35A0-8BFB-58EB-AF2A-16462F2177D3', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Eurasian lynx', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('8F37C065-0B4D-5D31-8A2D-3CADC6969C25', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Iberian lynx', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('ECD51BEB-2B0C-5910-BBCF-3149A18425B9', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Cheetah', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('A69E8840-DAB4-5102-BD7E-441CF131ECDE', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Jaguarundi', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('9C7400B7-4811-5D14-978D-851802E6BE87', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Puma', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('8A353386-8720-559D-AEC4-3EBACBF55E05', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Pallas''s cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('9D0C9E36-2372-50DA-BCC1-8564B38A072B', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Rusty-spotted cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('53BFC34B-3A11-5874-97D9-CC2A2D562A48', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Flat-headed cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('288425EA-7805-5C03-BF78-B7B13362F4F7', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Fishing cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('B9FFA089-13FF-5B97-84F4-5AB244277A2B', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Leopard cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('33F0F4D6-6B44-5339-B0A7-3CA1657FB9F8', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Sunda leopard cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('8634E01F-E282-5CEC-A7F2-8AD3FA18C101', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Jungle cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('B10BDD5B-7E8B-5794-B1CD-E3D8028189BE', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Black-footed cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('1889AB7A-E2FB-5572-9759-C08B5F07E4B7', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Sand cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('DF949B00-F2BD-534C-91B7-697EEC23EE60', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Chinese mountain cat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('ED542B2E-FBC9-5313-A837-CD842CE2A30E', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'Afro-Asiatic wildcat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
INSERT INTO "species" ("id", "taxonID", "name", "icon")
VALUES ('F18E7178-29C5-5FDF-B533-D0D388770A61', 'ADA89CE5-9B4C-571E-80BD-054887CEE842', 'European wildcat', '🐈')
ON CONFLICT("id") DO UPDATE SET "taxonID" = excluded."taxonID", "name" = excluded."name", "icon" = excluded."icon";
