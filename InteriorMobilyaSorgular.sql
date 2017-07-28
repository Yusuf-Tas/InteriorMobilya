
--3.	Müþteri Id alarak, bu müþterinin geçmiþ sipariþlerine ve diðer müþterilerin sipariþlerine bakarak bir ürün öneri procedure’ü yazýnýz. 
Create Proc MusteriSiparis (@MusteriID int)
As

Select * from
(select SehirAdi,Urun,ToplamAdet, Dense_rank() OVER(Partition By SehirAdi order by ToplamAdet DESC) AS Sira
from
(Select (Select SehirAdi from Sehir where SehirID in (Select AliciSehirID from Siparis where SiparisID=sd.SiparisID)) SehirAdi  ,

(Select UrunAdi from Urun where UrunID in (Select UrunID from Paketleme where PaketID in (Select PaketID from Siparis where SiparisID=sd.SiparisID))) Urun ,

(Select Sum(Adet) over (partition by (select UlkeAdi from Ulke where UlkeID in (Select UlkeID from Sehir where SehirID in (Select AliciSehirID from Siparis where SiparisID=sd.SiparisID)))) from Paketleme where PaketID in (Select PaketID from Siparis where SiparisID=sd.SiparisID)) ToplamAdet  

From SiparisDetay sd where SiparisID in (Select SiparisID from Siparis where AliciSehirID in (Select (Select SehirID from Sehir where SehirID in (Select AliciSehirID from Siparis where SiparisID=sd.SiparisID)) UlkeAdi  From SiparisDetay sd where SiparisID in (select SiparisID From Siparis where MusteriID=@MusteriID)
)))tb1)tb2
where Sira=1

--Müþterinin sehirlerini aldýktan sonra sipariþlere bakarak bu sehirden diðer musteriler en çok hangi ürünleri sipariþ etmiþ gördükten sonra bu ürünleri önerebiliriz.


--4.	Bu database üzerinde aþaðýdaki RDL raporlarýný hazýrlayýnýz.  *
--a.	Toplam ücret olarak ortalama satýþ miktarýnýn üzerine çýkan satýþlarýmdan ilk 50 sine ait ürünleri listeleyiniz.

Select top 50 UrunAdi,Toplam From
(Select (Select UrunAdi From Urun where UrunID in (Select UrunID from Paketleme where PaketID in (Select PaketID from Siparis where SiparisID=sd.SiparisID))) UrunAdi,(Select Sum(sd.Fiyat*Adet*(1-Indirim)) Over(partition by (Select UrunAdi From Urun where UrunID in (Select UrunID from Paketleme where PaketID in (Select PaketID from Siparis where SiparisID=sd.SiparisID))) ) From Paketleme where PaketID in (Select PaketID from Siparis where SiparisID=sd.SiparisID) ) Toplam From SiparisDetay sd 
where (Select Sum(sd.Fiyat*Adet*(1-Indirim)) Over(partition by (Select UrunAdi From Urun where UrunID in (Select UrunID from Paketleme where PaketID in (Select PaketID from Siparis where SiparisID=sd.SiparisID))) ) From Paketleme where PaketID in (Select PaketID from Siparis where SiparisID=sd.SiparisID) )>
(Select AVG(sd.Fiyat*p.Adet*(1-sd.Indirim)) Fiyat From Siparis s 
join SiparisDetay sd on s.SiparisID=sd.SiparisID
join Paketleme p on s.PaketID=p.PaketID))tb1
order by toplam desc

--b.	Adet olarak en çok satýn alýnan ürünü satýn alan müþterilerin ülkelerine hangi yýllarda kaç adet ürün satýþý yapýlmýþtýr?

Select 
(Select Ad+' '+Soyad   From Bireysel where MusteriID in (Select MusteriID from Musteri where MusteriID=s.MusteriID)) BireyselMusteri,(Select SirketAdi   From Kurumsal where MusteriID in (Select MusteriID from Musteri where MusteriID=s.MusteriID)) KurumsalMusteri,(Select UlkeAdi From Ulke where UlkeID in (Select UlkeID from Sehir where SehirID=s.AliciSehirID)) UlkeAdi,Year(s.SiparisTarihi) Yýl,(Select Sum(Adet)  From Paketleme where PaketID=s.PaketID) Toplam From Siparis s where s.PaketID in (Select PaketID from Paketleme where UrunID in (Select UrunID from Urun where UrunAdi=(Select UrunAdi From
(Select distinct Top 1 u.UrunAdi,Sum(p.Adet) Over(partition by u.UrunAdi) Sayi From Siparis s join Paketleme p on s.PaketID=p.PaketID
join Urun u on p.UrunID=u.UrunID
order by Sayi desc)tb1)))

--c.	Adet olarak toplam 100 ün üzerinde ürün satýlmýþ hangi kategorilerden, hangi ülkelere ücret olarak toplam ne kadarlýk satýþ yapýlmýþtýr?

Select (Select UlkeAdi From Ulke where UlkeID in (Select UlkeID from Sehir where SehirID in(Select AliciSehirID from Siparis where SiparisID=sd.SiparisID))) Ulke,(Select Sum(sd.Fiyat*Adet*(1-sd.Indirim)) Over(partition by (Select UlkeAdi From Ulke where UlkeID in (Select UlkeID from Sehir where SehirID in(Select AliciSehirID from Siparis where SiparisID=sd.SiparisID))) ) From Paketleme where PaketID in (select PaketID from Siparis where SiparisID=sd.SiparisID)) ToplamFiyat From SiparisDetay sd where SiparisID in (select SiparisID from Siparis where PaketID in (Select PaketID from Paketleme where UrunID in (Select UrunID from Urun where KategoriID in (select KategoriID from Kategori where KategoriAdi in ((Select KategoriAdi from 
(Select distinct k.KategoriAdi,Sum(Adet) over(partition by k.KategoriAdi) Toplam from Siparis s join Paketleme p on s.PaketID=p.PaketID
join urun u on p.UrunID=u.UrunID
join Kategori k on k.KategoriID=u.KategoriID )tb1
where Toplam>100))))))

--d.	Hangi ülkelere hangi ürünler için kaç kere satýþ sonrasý desteði saðlanmýþtýr?
Select distinct u.UlkeAdi,uu.UrunAdi,Count(d.DestekID) over(partition by u.UlkeAdi,uu.UrunAdi) Adet From Destek d join SiparisDetay sd on d.SiparisDetayID=sd.SiparisDetayID join Siparis s on sd.SiparisID=s.SiparisID join Sehir ss on ss.SehirID=s.AliciSehirID join Ulke u on ss.UlkeID=u.UlkeID
join Paketleme p on s.PaketID=p.PaketID join Urun uu on p.UrunID=uu.UrunID

--e.	Þimdiye kadar hiç yerinde kurulum yapýlmamýþ ürünlerden hangi yýl ücret olarak ortalama ne kadar satýþ yapýlmýþtýr?

Select (Select UrunAdi from Urun where UrunID in(select UrunID from Paketleme where PaketID in (select PaketID from Siparis where SiparisID=sd.SiparisID))) UrunAdi,(Select year(SiparisTarihi) from Siparis where SiparisID=sd.SiparisID) SiparisYili,(Select AVG(sd.Fiyat*Adet*(1-sd.Indirim)) over(partition by (Select year(SiparisTarihi) from Siparis where SiparisID=sd.SiparisID) ) From Paketleme where PaketID in(select paketID from Siparis where SiparisID=sd.SiparisID)) OrtalamaUcret From SiparisDetay sd where SiparisDetayID not in (Select SiparisDetayID From Destek)