-- Câu hỏi SQL từ cơ bản đến nâng cao, bao gồm trigger

-- Cơ bản:
1. Liệt kê tất cả chuyên gia trong cơ sở dữ liệu.
SELECT * FROM ChuyenGia;

2. Hiển thị tên và email của các chuyên gia nữ.
SELECT HoTen, Email FROM ChuyenGia WHERE GioiTinh = N'Nữ';

3. Liệt kê các công ty có trên 100 nhân viên.
SELECT * FROM CongTy WHERE SoNhanVien > 100;

4. Hiển thị tên và ngày bắt đầu của các dự án trong năm 2023.
SELECT TenDuAn, NgayBatDau FROM DuAn WHERE YEAR(NgayBatDau) = 2023;

5. Đếm số lượng chuyên gia trong mỗi chuyên ngành.
SELECT ChuyenNganh, COUNT(*) AS SoLuong FROM ChuyenGia GROUP BY ChuyenNganh;

-- Trung cấp:
6. Liệt kê tên chuyên gia và số lượng dự án họ tham gia.
SELECT CG.HoTen, COUNT(CGDA.MaDuAn) AS SoDuAn
FROM ChuyenGia CG
LEFT JOIN ChuyenGia_DuAn CGDA ON CG.MaChuyenGia = CGDA.MaChuyenGia
GROUP BY CG.MaChuyenGia, CG.HoTen;

7. Tìm các dự án có sự tham gia của chuyên gia có kỹ năng 'Python' cấp độ 4 trở lên.
SELECT DISTINCT DA.TenDuAn
FROM DuAn DA
JOIN ChuyenGia_DuAn CGDA ON DA.MaDuAn = CGDA.MaDuAn
JOIN ChuyenGia_KyNang CGKN ON CGDA.MaChuyenGia = CGKN.MaChuyenGia
JOIN KyNang KN ON CGKN.MaKyNang = KN.MaKyNang
WHERE KN.TenKyNang = 'Python' AND CGKN.CapDo >= 4;

8. Hiển thị tên công ty và số lượng dự án đang thực hiện.
SELECT CongTy.TenCongTy, COUNT(DuAn.MaDuAn) AS SoDuAnDangThucHien
FROM CongTy
LEFT JOIN DuAn ON CongTy.MaCongTy = DuAn.MaCongTy
WHERE DuAn.TrangThai = N'Đang thực hiện'
GROUP BY CongTy.MaCongTy, CongTy.TenCongTy;

9. Tìm chuyên gia có số năm kinh nghiệm cao nhất trong mỗi chuyên ngành.
WITH RankedChuyenGia AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY ChuyenNganh ORDER BY NamKinhNghiem DESC) AS Rank
    FROM ChuyenGia
)
SELECT HoTen, ChuyenNganh, NamKinhNghiem
FROM RankedChuyenGia
WHERE Rank = 1;

10. Liệt kê các cặp chuyên gia đã từng làm việc cùng nhau trong ít nhất một dự án.
SELECT DISTINCT 
    CG1.HoTen AS ChuyenGia1, 
    CG2.HoTen AS ChuyenGia2, 
    DA.TenDuAn
FROM ChuyenGia_DuAn CGDA1
JOIN ChuyenGia_DuAn CGDA2 ON CGDA1.MaDuAn = CGDA2.MaDuAn AND CGDA1.MaChuyenGia < CGDA2.MaChuyenGia
JOIN ChuyenGia CG1 ON CGDA1.MaChuyenGia = CG1.MaChuyenGia
JOIN ChuyenGia CG2 ON CGDA2.MaChuyenGia = CG2.MaChuyenGia
JOIN DuAn DA ON CGDA1.MaDuAn = DA.MaDuAn;

-- Nâng cao:
11. Tính tổng thời gian (theo ngày) mà mỗi chuyên gia đã tham gia vào các dự án.
SELECT CG.HoTen,
       SUM(DATEDIFF(DAY, CGDA.NgayThamGia, COALESCE(CGDA.NgayKetThuc, GETDATE()))) AS TongThoiGian
FROM ChuyenGia CG
JOIN ChuyenGia_DuAn CGDA ON CG.MaChuyenGia = CGDA.MaChuyenGia
GROUP BY CG.MaChuyenGia, CG.HoTen;

12. Tìm các công ty có tỷ lệ dự án hoàn thành cao nhất (trên 90%).
WITH DuAnStats AS (
    SELECT MaCongTy,
           COUNT(*) AS TotalProjects,
           SUM(CASE WHEN TrangThai = N'Hoàn thành' THEN 1 ELSE 0 END) AS CompletedProjects
    FROM DuAn
    GROUP BY MaCongTy
)
SELECT CongTy.TenCongTy, 
       (CAST(DuAnStats.CompletedProjects AS FLOAT) / DuAnStats.TotalProjects) * 100 AS TyLeHoanThanh
FROM CongTy
JOIN DuAnStats ON CongTy.MaCongTy = DuAnStats.MaCongTy
WHERE (CAST(DuAnStats.CompletedProjects AS FLOAT) / DuAnStats.TotalProjects) > 0.9;

13. Liệt kê top 3 kỹ năng được yêu cầu nhiều nhất trong các dự án.
WITH KyNangYeuCau AS (
    SELECT KN.MaKyNang, KN.TenKyNang, COUNT(DISTINCT DA.MaDuAn) AS SoLanYeuCau
    FROM KyNang KN
    JOIN ChuyenGia_KyNang CGKN ON KN.MaKyNang = CGKN.MaKyNang
    JOIN ChuyenGia_DuAn CGDA ON CGKN.MaChuyenGia = CGDA.MaChuyenGia
    JOIN DuAn DA ON CGDA.MaDuAn = DA.MaDuAn
    GROUP BY KN.MaKyNang, KN.TenKyNang
)
SELECT TOP 3 TenKyNang, SoLanYeuCau
FROM KyNangYeuCau
ORDER BY SoLanYeuCau DESC;

14. Tính lương trung bình của chuyên gia theo từng cấp độ kinh nghiệm (Junior: 0-2 năm, Middle: 3-5 năm, Senior: >5 năm).
SELECT 
    CASE 
        WHEN NamKinhNghiem <= 2 THEN 'Junior'
        WHEN NamKinhNghiem <= 5 THEN 'Middle'
        ELSE 'Senior'
    END AS CapDo,
    AVG(Luong) AS LuongTrungBinh
FROM ChuyenGia
GROUP BY 
    CASE 
        WHEN NamKinhNghiem <= 2 THEN 'Junior'
        WHEN NamKinhNghiem <= 5 THEN 'Middle'
        ELSE 'Senior'
    END;

15. Tìm các dự án có sự tham gia của chuyên gia từ tất cả các chuyên ngành.
WITH SpecializationCount AS (
    SELECT COUNT(DISTINCT ChuyenNganh) AS TotalSpecializations
    FROM ChuyenGia
), ProjectSpecializations AS (
    SELECT DA.MaDuAn, COUNT(DISTINCT CG.ChuyenNganh) AS SpecializationsCount
    FROM DuAn DA
    JOIN ChuyenGia_DuAn CGDA ON DA.MaDuAn = CGDA.MaDuAn
    JOIN ChuyenGia CG ON CGDA.MaChuyenGia = CG.MaChuyenGia
    GROUP BY DA.MaDuAn
)
SELECT DA.TenDuAn
FROM DuAn DA
JOIN ProjectSpecializations PS ON DA.MaDuAn = PS.MaDuAn
CROSS JOIN SpecializationCount
WHERE PS.SpecializationsCount = SpecializationCount.TotalSpecializations;

-- Trigger:
16. Tạo một trigger để tự động cập nhật số lượng dự án của công ty khi thêm hoặc xóa dự án.
CREATE TRIGGER trg_CapNhatSoDuAnCongTy
ON DuAn
AFTER INSERT, DELETE
AS
BEGIN
    -- Cập nhật cho các công ty có dự án mới thêm
    UPDATE CongTy
    SET SoDuAn = SoDuAn + 1
    FROM CongTy
    INNER JOIN inserted ON CongTy.MaCongTy = inserted.MaCongTy;

    -- Cập nhật cho các công ty có dự án bị xóa
    UPDATE CongTy
    SET SoDuAn = SoDuAn - 1
    FROM CongTy
    INNER JOIN deleted ON CongTy.MaCongTy = deleted.MaCongTy;
END;

17. Tạo một trigger để ghi log mỗi khi có sự thay đổi trong bảng ChuyenGia.
CREATE TABLE ChuyenGiaLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    MaChuyenGia INT,
    HanhDong NVARCHAR(10),
    NgayThayDoi DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_LogChuyenGia
ON ChuyenGia
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @HanhDong NVARCHAR(10);
    
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @HanhDong = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @HanhDong = 'INSERT';
    ELSE
        SET @HanhDong = 'DELETE';
    
    INSERT INTO ChuyenGiaLog (MaChuyenGia, HanhDong)
    SELECT MaChuyenGia, @HanhDong
    FROM inserted
    UNION ALL
    SELECT MaChuyenGia, @HanhDong
    FROM deleted;
END;

18. Tạo một trigger để đảm bảo rằng một chuyên gia không thể tham gia vào quá 5 dự án cùng một lúc.
CREATE TRIGGER trg_GioiHanDuAn
ON ChuyenGia_DuAn
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT MaChuyenGia
        FROM ChuyenGia_DuAn
        GROUP BY MaChuyenGia
        HAVING COUNT(DISTINCT MaDuAn) > 5
    )
    BEGIN
        RAISERROR ('Một chuyên gia không thể tham gia vào quá 5 dự án cùng một lúc.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

19. Tạo một trigger để tự động cập nhật trạng thái của dự án thành 'Hoàn thành' khi tất cả chuyên gia đã kết thúc công việc.
CREATE TRIGGER trg_CapNhatTrangThaiDuAn
ON ChuyenGia_DuAn
AFTER UPDATE
AS
BEGIN
    UPDATE DuAn
    SET TrangThai = N'Hoàn thành'
    WHERE MaDuAn IN (
        SELECT MaDuAn
        FROM ChuyenGia_DuAn
        GROUP BY MaDuAn
        HAVING COUNT(*) = SUM(CASE WHEN NgayKetThuc IS NOT NULL THEN 1 ELSE 0 END)
    )
    AND TrangThai != N'Hoàn thành';
END;

20. Tạo một trigger để tự động tính toán và cập nhật điểm đánh giá trung bình của công ty dựa trên điểm đánh giá của các dự án.
CREATE TRIGGER trg_CapNhatDiemDanhGiaCongTy
ON DuAn
AFTER UPDATE
AS
BEGIN
    IF UPDATE(DiemDanhGia)
    BEGIN
        UPDATE CongTy
        SET DiemDanhGia = (
            SELECT AVG(DiemDanhGia)
            FROM DuAn
            WHERE MaCongTy = CongTy.MaCongTy AND DiemDanhGia IS NOT NULL
        )
        FROM CongTy
        INNER JOIN inserted ON CongTy.MaCongTy = inserted.MaCongTy;
    END
END;
