﻿CREATE DATABASE THITHU3
USE THITHU3
GO

CREATE TABLE DOCGIA
(
	MADG CHAR(5),
	HOTEN VARCHAR(30),
	NGAYSINH SMALLDATETIME,
	DIACHI VARCHAR(30),
	SODT VARCHAR(15),
	PRIMARY KEY (MADG)
)

CREATE TABLE SACH
(
	MASACH CHAR(5),
	TENSACH VARCHAR(25),
	THELOAI VARCHAR(25),
	NHAXUATBAN VARCHAR(30),
	PRIMARY KEY(MASACH)
)

CREATE TABLE PHIEUTHUE
(
	MAPT CHAR(5),
	MADG CHAR(5),
	NGAYTHUE SMALLDATETIME,
	NGAYTRA SMALLDATETIME,
	SOSACHTHUE INT,
	PRIMARY KEY (MAPT),
	FOREIGN KEY (MADG) REFERENCES DOCGIA(MADG)
)

CREATE TABLE CHITIET_PT
(
	MAPT CHAR(5),
	MASACH CHAR(5),
	PRIMARY KEY (MAPT,MASACH),
	FOREIGN KEY (MAPT) REFERENCES PHIEUTHUE(MAPT),
	FOREIGN KEY (MASACH) REFERENCES SACH(MASACH)
)

--2.1. Mỗi lần thuê  sách, độc giả không được thuê quá 10 ngày. (1.5 đ)  
--2.2. Số sách thuê trong bảng phiếu thuê bằng tổng số lần thuê sách có trong bảng chi tiết phiếu thuê. (1.5 đ) 

ALTER TABLE PHIEUTHUE
ADD CONSTRAINT CHK_DATE CHECK( DATEDIFF(DAY,NGAYTRA,NGAYTHUE) <= 10)

CREATE TRIGGER A
ON CHITIET_PT
FOR UPDATE,DELETE,INSERT
AS
BEGIN
	IF EXISTS(
		SELECT 1 
		FROM PHIEUTHUE PT
		WHERE SOSACHTHUE != (
			SELECT COUNT(*) 
			FROM CHITIET_PT
			WHERE CHITIET_PT.MAPT = PT.MAPT
		)
	)
	BEGIN
		ROLLBACK TRANSACTION
	END
END
--3. Viết các câu lệnh SQL thực hiện các câu truy vấn sau:  
--3.1. Tìm các độc giả (MaDG,HoTen) đã thuê sách thuộc thể loại “Tin học” trong năm 2007. (1.5 đ)  
SELECT DOCGIA.MADG,HOTEN
FROM DOCGIA
JOIN PHIEUTHUE ON  PHIEUTHUE.MADG = DOCGIA.MADG
JOIN CHITIET_PT ON CHITIET_PT.MAPT = PHIEUTHUE.MAPT
JOIN SACH ON CHITIET_PT.MASACH = SACH.MASACH
WHERE THELOAI = N'TIN HOC' AND YEAR(NGAYTHUE) = 2007
--3.2. Tìm các độc giả (MaDG,HoTen) đã thuê nhiều thể loại sách nhất. (1.5 đ)  
SELECT TOP 1 WITH TIES DOCGIA.MADG,HOTEN, COUNT(DISTINCT THELOAI) AS SOTHELOAI
FROM DOCGIA
JOIN PHIEUTHUE ON  PHIEUTHUE.MADG = DOCGIA.MADG
JOIN CHITIET_PT ON CHITIET_PT.MAPT = PHIEUTHUE.MAPT
JOIN SACH ON CHITIET_PT.MASACH = SACH.MASACH
GROUP BY DOCGIA.MADG,HOTEN
ORDER BY SOTHELOAI DESC
--3.3. Trong mỗi thể loại sách, cho biết tên sách được thuê nhiều nhất. (1 đ)  
SELECT THELOAI, TENSACH 
FROM SACH
JOIN CHITIET_PT ON CHITIET_PT.MASACH = SACH.MASACH
JOIN PHIEUTHUE ON PHIEUTHUE.MAPT = CHITIET_PT.MAPT
GROUP BY THELOAI,TENSACH
HAVING COUNT(*) = (
	SELECT MAX(COUNT(*))
	FROM SACH S
	JOIN CHITIET_PT ON CHITIET_PT.MASACH = SACH.MASACH
	JOIN PHIEUTHUE ON PHIEUTHUE.MAPT = CHITIET_PT.MAPT
	WHERE S.MASACH = SACH.MASACH
_


