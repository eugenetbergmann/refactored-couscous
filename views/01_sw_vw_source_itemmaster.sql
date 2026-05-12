-- SW_vw_Source_ItemMaster
-- Adapter View: Item master with core attributes, quantities, and vendor assignment
-- SQL Server 2016 compatible, NOLOCK required
--
-- This is the SLIM base view. Enrichment (consumption stats, risk, SS) lives
-- in SW_vw_Source_ItemMaster_Detail.

CREATE VIEW dbo.SW_vw_Source_ItemMaster
AS
WITH ItemBase AS (
    SELECT
        TRIM(i.ITEMNMBR) AS ITEMNMBR,
        TRIM(i.ITEMDESC) AS ITEMDESC,
        TRIM(i.ITMCLSCD) AS ITMCLSCD,
        TRIM(i.UOMSCHDL) AS UOM,
        LEFT(TRIM(i.ITEMNMBR),
             LEN(TRIM(i.ITEMNMBR)) - CHARINDEX('.', REVERSE(TRIM(i.ITEMNMBR)))) AS Base_ITEMNMBR,
        RIGHT(TRIM(i.ITEMNMBR),
              CHARINDEX('.', REVERSE(TRIM(i.ITEMNMBR))) - 1) AS Suffix,
        COALESCE(q.QTYONHND, 0) AS QtyOnHand,
        COALESCE(q.QTYONORD, 0) AS QtyOnOrder,
        COALESCE(q.QTYBKORD, 0) AS QtyBackOrdered,
        COALESCE(v.VENDORID, 'UNASSIGNED') AS PRIME_VNDR,
        CAST(GETDATE() AS DATE) AS AsOfDate
    FROM dbo.IV00101 i WITH (NOLOCK)
    LEFT JOIN dbo.IV00102 q WITH (NOLOCK)
        ON TRIM(i.ITEMNMBR) = TRIM(q.ITEMNMBR)
    LEFT JOIN dbo.Prosenthal_Vendor_Items v WITH (NOLOCK)
        ON TRIM(i.ITEMNMBR) = TRIM(v.[Item Number])
     WHERE i.ITEMNMBR NOT LIKE '20%'
      AND i.ITEMNMBR NOT LIKE '15%'
)
SELECT * FROM ItemBase;