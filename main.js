// Snow Temizlik - teklif formu WhatsApp'a mesaj olarak gönderir
const WA_NUMBER = "905536682525";
document.querySelectorAll("form.wa-form").forEach(function (f) {
  f.addEventListener("submit", function (e) {
    e.preventDefault();
    const v = n => (f.elements[n] ? f.elements[n].value.trim() : "");
    const msg = [
      "Merhaba, " + (v("hizmet") || f.dataset.service) + " için fiyat almak istiyorum.",
      "Ad: " + v("ad"),
      v("tur") ? "Mekan: " + v("tur") : "",
      v("m2") ? "Metrekare: " + v("m2") : "",
      v("ilce") ? "Konum: " + v("ilce") : "",
      v("tarih") ? "Tarih: " + v("tarih") : "",
      v("notlar") ? "Not: " + v("notlar") : "",
      "(Fotoğrafları bu mesajın ardından gönderiyorum.)"
    ].filter(Boolean).join("\n");
    window.open("https://wa.me/" + WA_NUMBER + "?text=" + encodeURIComponent(msg), "_blank");
  });
});
