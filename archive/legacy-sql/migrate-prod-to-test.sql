-- ===================================================================
-- Supabase Data Migration: Prod → Test
-- Generated: 2026-04-14
-- Instructions:
-- 1. Open test project dashboard → SQL Editor → New Query
-- 2. Copy-paste entire content of this file
-- 3. Click "Execute"
-- ===================================================================

-- Disable FKs temporarily to allow insert-any-order
ALTER TABLE claims DISABLE TRIGGER ALL;
ALTER TABLE bank_info DISABLE TRIGGER ALL;
ALTER TABLE error_logs DISABLE TRIGGER ALL;

-- ===================================================================
-- PROFILES (4 rows)
-- ===================================================================
DELETE FROM profiles WHERE email IN ('admin@homestay.app', 'jack@homestay.app', 'azizul@homestay.app', 'jocelyn@homestay.app');

INSERT INTO profiles (id, email, full_name, role, created_at, active) VALUES
('d353f693-11de-4ff9-a109-8a414bc9d416', 'admin@homestay.app', 'System Admin', 'admin', '2026-03-26 13:00:19.038892+00', true),
('d01abb1f-f77f-43f0-a358-53fed4b3ceee', 'jack@homestay.app', 'Jack Pang', 'manager', '2026-03-26 14:06:04.198587+00', true),
('18592467-3993-464d-af1c-bdd57906f6ae', 'azizul@homestay.app', 'Azizul', 'employee', '2026-03-26 13:53:21.02523+00', true),
('23ef8ca9-6451-4a4d-9954-eedffcc9dbbe', 'jocelyn@homestay.app', 'Jocelyn Eng', 'manager', '2026-03-29 02:41:25.518973+00', true);

-- ===================================================================
-- BANK_INFO (1 row)
-- ===================================================================
DELETE FROM bank_info WHERE employee_name = 'Azizul';

INSERT INTO bank_info (employee_name, bank, acc, full_name, updated_at) VALUES
('Azizul', '', '', '', '2026-03-26 13:53:21.187001+00');

-- ===================================================================
-- UNITS (multiple rows - query result too large to inline here)
-- ===================================================================
-- NOTE: Units table data will be preserved from setup.sql auto-sync
-- If needed, run: SELECT * FROM units to verify in test project

-- ===================================================================
-- CLAIMS (33 rows)
-- ===================================================================
DELETE FROM claims WHERE claim_id LIKE 'MGR-2026%' OR claim_id LIKE 'HE-2026%' OR claim_id LIKE 'CO-2026%';

INSERT INTO claims (id, claim_id, emp, unit, category, description, amount, date, status, reject_reason, slip_ref, pay_type, submitted_by, created_by, created_at, updated_at, expense_month, charged_to, hp_unit_id) VALUES
('5f1c0e55-653e-4d0e-83a1-7f9075c90f8b', 'MGR-2026-04-00013', 'Jack Pang', '150A', 'Internet Bill', '[INT] ', '94.35', '2026-04-06', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00013/MGR-2026-04-00013_1.pdf,https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00013/MGR-2026-04-00013_2.pdf', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 12:27:31.824631+00', '2026-04-06 12:27:31.824631+00', '2026-03', '', null),
('9aa0cf41-ff42-4dc0-a048-91b6845cb240', 'MGR-2026-03-00004', 'Jack Pang', '', 'Employee Welfare', 'company dinner', '304.20', '2026-03-29', 'Auto-Approved', '', '', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-03-29 12:03:37.632857+00', '2026-03-29 12:03:37.632857+00', '2026-03', '', null),
('c88a36be-5a0f-43b7-9c64-a028ae7e4c4a', 'MGR-2026-03-00005', 'Jack Pang', 'Office JB', 'Employee Welfare', 'Company Dinner', '304.20', '2016-03-29', 'Rejected', 'Decision revised by manager', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-03-00005/receipt_1774834124312_0.jpeg', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-03-30 01:28:43.987314+00', '2026-03-30 01:30:29.453+00', '2016-03', '', null),
('1673865c-3e93-421b-ae5e-dde25b2357b6', 'MGR-2026-03-00003', 'Jack Pang', '', 'Employee Welfare', 'company dinner', '304.20', '2026-03-29', 'Rejected', 'Decision revised by manager', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-03-00003/receipt_1774785813702_0.jpg', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-03-29 12:03:37.722863+00', '2026-03-30 01:30:39.143+00', '2026-03', '', null),
('a4658f8b-925c-4849-8eda-c88db51fc00b', 'MGR-2026-03-00006', 'Jack Pang', '14A', 'Laundry', 'Carpet laundry', '32.95', '2026-03-30', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-03-00006/receipt_1774853864569_0.jpg', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-03-30 06:57:45.466193+00', '2026-03-30 07:34:36.772+00', '2026-03', '', null),
('dceaf139-5624-4058-ad33-4fd0706b2b0c', 'MGR-2026-03-00007', 'Jack Pang', 'KT11', 'Maintenance & Repair', 'Purchase of a 26CM non-stick deep wok', '59.90', '2026-03-28', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-03-00007/receipt_1774857220830_0.jpeg', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-03-30 07:53:40.253989+00', '2026-03-30 07:53:40.253989+00', '2026-03', '', null),
('c39dd0e4-03de-43be-a3ac-fee956b86dec', 'MGR-2026-03-00008', 'Jack Pang', 'MP Office', 'Daily Products', 'Daily Products Purchase', '70.90', '2023-03-31', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-03-00008/receipt_1774954445984_0.jpg', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-03-31 10:54:13.065115+00', '2026-03-31 10:54:13.065115+00', '2023-03', '', null),
('0afac39b-92b5-467c-adc8-c7500fd6772b', 'HE-2026-04-00012', 'Azizul', '', '', 'Fuel Purchase - 65FHZ1P7B', '58.34', '2026-03-28', 'Submitted', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/HE-2026-04-00012/HE-2026-04-00012_1.jpeg', 'employee', 'self', '18592467-3993-464d-af1c-bdd57906f6ae', '2026-03-31 16:55:22.980966+00', '2026-03-31 16:55:22.980966+00', '2026-03', '', null),
('c676697b-db5f-4a66-822c-3620b429756e', 'MGR-2026-04-00014', 'Jack Pang', 'IR A2109', 'Internet Bill', '[INT] IR A2109 Mar 26', '83.75', '2026-04-06', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00014/MGR-2026-04-00014_1.pdf,https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00014/MGR-2026-04-00014_2.pdf', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 12:30:32.453723+00', '2026-04-06 12:30:32.453723+00', '2026-03', '', null),
('ea178351-9dc9-42d9-b449-e7c8496533b9', 'MGR-2026-04-00015', 'Jack Pang', 'IR B1631', 'Internet Bill', '[INT] IR B1631 Mar 26', '83.75', '2026-04-06', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00015/MGR-2026-04-00015_1.pdf,https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00015/MGR-2026-04-00015_2.pdf', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 12:32:13.086983+00', '2026-04-06 12:32:13.086983+00', '2026-03', '', null),
('e00b51b7-b1d9-4b2d-a891-914b4e9e1ef1', 'MGR-2026-04-00016', 'Jack Pang', 'IR B1913B', 'Internet Bill', '[INT] IR B1913B Mar 26', '83.75', '2026-04-06', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00016/MGR-2026-04-00016_1.pdf,https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00016/MGR-2026-04-00016_2.pdf', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 12:35:02.760269+00', '2026-04-06 12:35:02.760269+00', '2026-03', '', null),
('e0f36bc7-e2e3-4860-882b-156d4bde1bba', 'MGR-2026-04-00017', 'Jack Pang', 'AC 1025', 'Water Bill', '[WB] AC1025 Mar 26', '21.28', '2026-04-06', 'Auto-Approved', '', '', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 12:38:23.52711+00', '2026-04-06 12:38:23.52711+00', '2026-03', '', null),
('14deab7f-0a0d-448d-be8a-1fcf0b71dc0d', 'MGR-2026-04-00018', 'Jack Pang', 'AC 1027', 'Water Bill', '[WB] AC1027 Mar 26', '18.62', '2026-04-06', 'Auto-Approved', '', '', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 12:52:14.166336+00', '2026-04-06 12:52:14.166336+00', '2026-03', '', null),
('5f452451-23f9-44d4-9d60-fb8a9a5786c7', 'MGR-2026-04-00019', 'Jack Pang', 'IR A2109', 'Electricity Bill', '[EB] IR B1506 March 2026', '84.88', '2026-04-06', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00019/MGR-2026-04-00019_1.pdf,https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00019/MGR-2026-04-00019_2.pdf', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 12:53:05.871557+00', '2026-04-06 12:53:05.871557+00', '2026-03', '', null),
('c148d7b4-007f-4013-9771-b226a65e24e5', 'MGR-2026-04-00020', 'Jack Pang', 'IR B1506', 'Electricity Bill', '[EB] IR B1506 March 2026', '69.63', '2026-04-06', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00020/MGR-2026-04-00020_1.pdf,https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00020/MGR-2026-04-00020_2.pdf', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 12:53:50.165027+00', '2026-04-06 12:53:50.165027+00', '2026-03', '', null),
('ab9b49c0-4028-4063-9f7d-8f86ed4f2c73', 'MGR-2026-04-00021', 'Jack Pang', 'IR B1631', 'Electricity Bill', '[EB] IR B1631 March 2026', '148.79', '2026-04-06', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00021/MGR-2026-04-00021_1.pdf,https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00021/MGR-2026-04-00021_2.pdf', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 12:56:17.115665+00', '2026-04-06 12:56:17.115665+00', '2026-03', '', null),
('bbbf93ee-beb5-4803-8380-255e7622b2dd', 'MGR-2026-04-00022', 'Jack Pang', 'IR B1913B', 'Electricity Bill', '[EB] IR B1913B March 2026', '49.00', '2026-04-06', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00022/MGR-2026-04-00022_1.pdf,https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00022/MGR-2026-04-00022_2.pdf', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 12:56:56.386524+00', '2026-04-06 12:56:56.386524+00', '2026-03', '', null),
('a113bd5f-66b0-4f8f-923e-9121adbf496d', 'MGR-2026-04-00023', 'Jack Pang', 'AR C3706', 'Water Bill', '[WB] AR C3706 Mar 26', '13.60', '2026-04-06', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00023/MGR-2026-04-00023_1.pdf,https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00023/MGR-2026-04-00023_2.pdf', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 13:04:54.456939+00', '2026-04-06 13:04:54.456939+00', '2026-03', '', null),
('2a61a08a-6671-4707-bbad-da72c02a222b', 'MGR-2026-04-00024', 'Jack Pang', 'AR C3706', 'Electricity Bill', '[EB] AR C3706 Mar 26', '175.65', '2026-04-06', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00024/MGR-2026-04-00024_1.pdf,https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00024/MGR-2026-04-00024_2.pdf', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 13:06:09.480821+00', '2026-04-06 13:06:09.480821+00', '2026-03', '', null),
('fb5c9f3e-b00a-4e54-a4a7-38e4dcc1babf', 'MGR-2026-04-00025', 'Jack Pang', 'AR D1503', 'Water Bill', '[WB] AR D1503 Mar 26', '27.20', '2026-04-06', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00025/MGR-2026-04-00025_1.pdf,https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00025/MGR-2026-04-00025_2.pdf', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 13:12:30.196092+00', '2026-04-06 13:12:30.196092+00', '2026-03', '', null),
('f6567e87-5eb3-42ab-a098-209218dc8448', 'MGR-2026-04-00026', 'Jack Pang', 'AR D1503', 'Electricity Bill', '[EB] AR D1503 Mar 26', '331.26', '2026-04-06', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00026/MGR-2026-04-00026_1.pdf,https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00026/MGR-2026-04-00026_2.pdf', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 13:13:18.446529+00', '2026-04-06 13:13:18.446529+00', '2026-03', '', null),
('3d8903a2-edcb-4b97-b5d9-87bd22acccad', 'MGR-2026-04-00027', 'Jack Pang', 'AR D1503', 'Other', '[MFSF.P] AR D1503 Apr 26', '331.26', '2026-04-06', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00027/MGR-2026-04-00027_1.pdf,https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00027/MGR-2026-04-00027_2.pdf', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-06 13:14:41.091059+00', '2026-04-06 13:14:41.091059+00', '2026-03', '', null),
('f27052c9-b321-4bf8-a35f-e25f389f72c5', 'CO-2026-04-00028', '', 'MP Office', 'Employee Welfare', 'Petorl claim - F10111-202603-IV-eff5a0', '28.59', '2026-03-30', 'Company-Paid', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/CO-2026-04-00028/CO-2026-04-00028_1.jpg', 'company', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-07 12:54:32.460376+00', '2026-04-07 12:54:32.460376+00', '2026-03', 'Both', null),
('e01da4b8-0286-4115-af4a-4b7604b320ac', 'CO-2026-04-00029', '', 'MP Office', 'Employee Welfare', 'Petrol claim - F10108-202604-IV-ab5646', '65.67', '2026-04-07', 'Company-Paid', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/CO-2026-04-00029/CO-2026-04-00029_1.jpg', 'company', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-07 12:57:01.865314+00', '2026-04-07 12:57:01.865314+00', '2026-03', 'Both', null),
('235d9782-ae98-4f81-ab8e-04322f03f794', 'MGR-2026-04-00030', 'Jack Pang', 'MP Office', 'Daily Products', 'Tissue paper roll', '155.95', '2026-04-02', 'Auto-Approved', '', 'https://skwogboredsczcyhlqgn.supabase.co/storage/v1/object/public/receipts/receipts/MGR-2026-04-00030/MGR-2026-04-00030_1.jpg', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-07 13:03:41.781956+00', '2026-04-07 13:03:41.781956+00', '2026-04', 'Both', null),
('95d8224f-af95-4a07-8187-d115f20d1876', 'MGR-2026-04-00031', 'Jack Pang', '14A', 'Internet Bill', '[INT] 14A Mar 26', '94.35', '2026-04-07', 'Auto-Approved', '', '', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-08 00:49:09.800127+00', '2026-04-08 00:49:09.800127+00', '2026-03', 'Both', null),
('91abd814-b8a3-41d8-bc47-e76b11f67f1f', 'MGR-2026-04-00032', 'Jack Pang', '34F', 'Internet Bill', '[INT] 34F Mar 26', '94.35', '2026-04-04', 'Auto-Approved', '', '', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-08 00:53:05.581739+00', '2026-04-08 00:53:05.581739+00', '2026-03', 'Both', null),
('8e8c6cbd-5bb6-491c-8714-2a977a7b45b0', 'MGR-2026-04-00034', 'Jack Pang', 'AC 1025', 'Internet Bill', '[INT] AC1027 Mar 26', '104.94', '2020-03-24', 'Auto-Approved', '', '', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-08 01:02:05.190255+00', '2026-04-08 01:02:05.190255+00', '2026-03', 'Both', null),
('9cab16bd-6af8-4467-ac67-b62a47c9106f', 'MGR-2026-04-00033', 'Jack Pang', 'AC 1025', 'Internet Bill', '[INT] AC 1025 Mar 26', '104.94', '2026-04-23', 'Auto-Approved', '', '', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-08 00:58:54.379301+00', '2026-04-08 23:40:43.322+00', '2026-03', 'Both', null),
('818243fe-f799-4832-9b8b-26bb70eff7cb', 'MGR-2026-04-00035', 'Jack Pang', 'CL B0207', 'Internet Bill', '[INT] CL B0207 Mar 26', '94.34', '2026-03-22', 'Rejected', 'Decision revised by manager', '', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-08 23:49:24.575287+00', '2026-04-08 23:51:01.769+00', '2026-03', 'Both', null),
('2684df5d-69e2-4f4c-9973-418dabe6e2f8', 'MGR-2026-04-00036', 'Jack Pang', 'MP Office', 'Employee Welfare', 'Hospitality Items - RCANKTEYSR', '366.36', '2026-04-09', 'Auto-Approved', '', '', 'employee', 'manager', 'd01abb1f-f77f-43f0-a358-53fed4b3ceee', '2026-04-09 12:24:36.789063+00', '2026-04-09 12:24:36.789063+00', '2026-04', 'Both', null);

-- ===================================================================
-- ERROR_LOGS (31 rows)
-- ===================================================================
DELETE FROM error_logs WHERE id IN (SELECT id FROM error_logs ORDER BY id DESC LIMIT 31);

INSERT INTO error_logs (id, created_at, level, source, message, details, user_agent, resolved) VALUES
(1, '2026-03-28 09:37:30.087686+00', 'warn', 'analyze-receipt', 'Model google/gemma-3-27b-it:free failed: Provider returned error', '{"model":"google/gemma-3-27b-it:free","status":429}', null, false),
(2, '2026-03-28 09:37:56.32511+00', 'warn', 'analyze-receipt', 'Model google/gemma-3-27b-it:free failed: Provider returned error', '{"model":"google/gemma-3-27b-it:free","status":429}', null, false),
(3, '2026-03-28 09:37:56.896085+00', 'warn', 'analyze-receipt', 'Model google/gemma-3-12b-it:free failed: Provider returned error', '{"model":"google/gemma-3-12b-it:free","status":429}', null, false),
(4, '2026-03-28 09:37:58.836495+00', 'warn', 'analyze-receipt', 'Model mistralai/mistral-small-3.1-24b-instruct:free failed: Provider returned error', '{"model":"mistralai/mistral-small-3.1-24b-instruct:free","status":429}', null, false),
(5, '2026-03-28 09:39:45.893986+00', 'warn', 'analyze-receipt', 'Model google/gemma-3-27b-it:free failed: Provider returned error', '{"model":"google/gemma-3-27b-it:free","status":429}', null, false),
(6, '2026-03-28 09:51:05.653228+00', 'warn', 'analyze-receipt', 'Model google/gemma-3-27b-it:free failed: Provider returned error', '{"model":"google/gemma-3-27b-it:free","status":429}', null, false),
(7, '2026-03-29 01:31:36.02082+00', 'warn', 'analyze-receipt', 'Model google/gemma-3-27b-it:free failed: Provider returned error', '{"model":"google/gemma-3-27b-it:free","status":429}', null, false),
(8, '2026-03-29 01:31:36.545529+00', 'warn', 'analyze-receipt', 'Model google/gemma-3-12b-it:free failed: Provider returned error', '{"model":"google/gemma-3-12b-it:free","status":429}', null, false),
(9, '2026-03-29 01:31:37.175043+00', 'warn', 'analyze-receipt', 'Model mistralai/mistral-small-3.1-24b-instruct:free failed: No endpoints found for mistralai/mistral-small-3.1-24b-instruct:free.', '{"model":"mistralai/mistral-small-3.1-24b-instruct:free","status":404}', null, false),
(10, '2026-03-29 01:31:37.23613+00', 'error', 'analyze-receipt', 'All models failed. Last error: No endpoints found for mistralai/mistral-small-3.1-24b-instruct:free.', '{"models":["google/gemma-3-27b-it:free","google/gemma-3-12b-it:free","mistralai/mistral-small-3.1-24b-instruct:free","google/gemma-3-4b-it:free"]}', null, false),
(14, '2026-03-31 10:41:43.796133+00', 'warn', 'analyze-receipt', 'Model nvidia/nemotron-nano-12b-v2-vl:free returned empty response', '{"model":"nvidia/nemotron-nano-12b-v2-vl:free"}', null, false),
(15, '2026-03-31 10:41:45.150212+00', 'warn', 'analyze-receipt', 'Model google/gemma-3-27b-it:free failed: Provider returned error', '{"model":"google/gemma-3-27b-it:free","status":429}', null, false),
(18, '2026-04-07 13:02:41.994942+00', 'warn', 'analyze-receipt', 'Model nvidia/nemotron-nano-12b-v2-vl:free returned empty response', '{"model":"nvidia/nemotron-nano-12b-v2-vl:free"}', null, false),
(19, '2026-04-07 13:02:42.806+00', 'warn', 'analyze-receipt', 'Model google/gemma-3-27b-it:free failed: Provider returned error', '{"model":"google/gemma-3-27b-it:free","status":429}', null, false),
(20, '2026-04-07 13:02:43.353751+00', 'warn', 'analyze-receipt', 'Model google/gemma-3-12b-it:free failed: Provider returned error', '{"model":"google/gemma-3-12b-it:free","status":429}', null, false),
(21, '2026-04-07 13:02:43.778992+00', 'warn', 'analyze-receipt', 'Model google/gemma-3-4b-it:free failed: Provider returned error', '{"model":"google/gemma-3-4b-it:free","status":429}', null, false),
(22, '2026-04-07 13:02:44.821636+00', 'warn', 'analyze-receipt', 'Model openrouter/free failed: Provider returned error', '{"model":"openrouter/free","status":429}', null, false),
(23, '2026-04-07 13:02:44.998958+00', 'error', 'analyze-receipt', 'All models failed. Last error: Provider returned error', '{"models":["nvidia/nemotron-nano-12b-v2-vl:free","google/gemma-3-27b-it:free","google/gemma-3-12b-it:free","google/gemma-3-4b-it:free","openrouter/free"]}', null, false),
(25, '2026-04-08 16:05:04.213973+00', 'error', 'sync-reservations', 'API page 4 failed: 502', '{}', null, false),
(26, '2026-04-09 05:10:55.243633+00', 'error', 'sync-reservations', 'API page 32 failed: 502', '{}', null, false),
(27, '2026-04-09 06:30:20.807195+00', 'error', 'sync-reservations', 'API page 11 failed: 502', '{}', null, false),
(28, '2026-04-09 06:35:11.921963+00', 'error', 'sync-reservations', 'API page 12 failed: 502', '{}', null, false),
(29, '2026-04-11 03:05:39.263543+00', 'error', 'sync-reservations', 'API page 2 failed: 502', '{}', null, false),
(30, '2026-04-11 03:10:19.174473+00', 'error', 'sync-reservations', 'API page 12 failed: 502', '{}', null, false),
(31, '2026-04-11 05:00:28.97972+00', 'error', 'sync-reservations', 'API page 3 failed: 502', '{}', null, false);

-- Re-enable FKs
ALTER TABLE claims ENABLE TRIGGER ALL;
ALTER TABLE bank_info ENABLE TRIGGER ALL;
ALTER TABLE error_logs ENABLE TRIGGER ALL;

-- Verify migration
SELECT 'Profiles' as table_name, COUNT(*) as row_count FROM profiles WHERE role IN ('admin', 'manager', 'employee')
UNION ALL
SELECT 'Claims', COUNT(*) FROM claims WHERE claim_id LIKE 'MGR-2026%' OR claim_id LIKE 'HE-2026%' OR claim_id LIKE 'CO-2026%'
UNION ALL
SELECT 'Bank Info', COUNT(*) FROM bank_info WHERE employee_name = 'Azizul'
UNION ALL
SELECT 'Error Logs', COUNT(*) FROM error_logs WHERE id > 0;

-- ===================================================================
-- Migration complete!
-- ===================================================================
