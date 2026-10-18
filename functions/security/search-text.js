function normalize(value) {
  return value.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f\u064B-\u065F\u0670\u0640]/g, '')
    .replace(/œ/g, 'oe').replace(/æ/g, 'ae')
    .replace(/[أإآٱ]/g, 'ا').replace(/[ىئ]/g, 'ي').replace(/ؤ/g, 'و').replace(/ة/g, 'ه')
    .replace(/[^\w\u0600-\u06FF]+/g, ' ').replace(/\s+/g, ' ').trim();
}
module.exports = {normalize};
