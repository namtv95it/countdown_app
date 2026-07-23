const project = 'lovin-c69f3';
const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/gifts`;

const sampleGifts = [
  {
    name: { vi: "Gấu Bông Capybara", en: "Capybara Plush" },
    description: { vi: "", en: "" },
    imageUrl: "https://down-vn.img.susercontent.com/file/vn-11134207-7r98o-lt3t5x8h4y6x0e",
    priceRange: "150k - 250k",
    badge: "HOT",
    platform: "Shopee",
    affiliateUrl: "https://shopee.vn/search?keyword=capybara",
    gender: "unisex",
    categoryIds: ["birthday", "love", "children_day"],
  },
  {
    name: { vi: "Son MAC Ruby Woo", en: "MAC Ruby Woo Lipstick" },
    description: { vi: "", en: "" },
    imageUrl: "https://down-vn.img.susercontent.com/file/sg-11134201-22100-q0wqk3n9z9iv46",
    priceRange: "500k - 650k",
    badge: "SALE",
    platform: "Lazada",
    affiliateUrl: "https://lazada.vn/",
    gender: "female",
    categoryIds: ["love", "anniversary", "womens_day"],
  },
  {
    name: { vi: "Đồng Hồ Casio Vintage", en: "Casio Vintage Watch" },
    description: { vi: "", en: "" },
    imageUrl: "https://down-vn.img.susercontent.com/file/vn-11134207-7r98o-lt3t6y9i5z7y1f",
    priceRange: "800k - 1tr2",
    badge: "SPECIAL",
    platform: "Shopee",
    affiliateUrl: "https://shopee.vn/",
    gender: "unisex",
    categoryIds: ["birthday", "anniversary"],
  },
  {
    name: { vi: "Bộ Xếp Hình Lego Hoa", en: "Lego Flower Bouquet" },
    description: { vi: "", en: "" },
    imageUrl: "https://down-vn.img.susercontent.com/file/vn-11134207-7qukw-lfz6v7x8y9z0a1",
    priceRange: "900k - 1tr5",
    badge: "NEW",
    platform: "Tiki",
    affiliateUrl: "https://tiki.vn/",
    gender: "female",
    categoryIds: ["birthday", "womens_day", "love"],
  },
  {
    name: { vi: "Tai Nghe Bluetooth Baseus", en: "Baseus Bluetooth Earbuds" },
    description: { vi: "", en: "" },
    imageUrl: "https://down-vn.img.susercontent.com/file/vn-11134201-7qukw-lesf8z9r78wqb1",
    priceRange: "300k - 450k",
    badge: "",
    platform: "Tiktok Shop",
    affiliateUrl: "https://tiktok.com/",
    gender: "unisex",
    categoryIds: ["birthday"],
  },
  {
    name: { vi: "Nến Thơm Agaya", en: "Agaya Scented Candle" },
    description: { vi: "", en: "" },
    imageUrl: "https://down-vn.img.susercontent.com/file/vn-11134207-7r98o-lt3t7z0j6a8z2g",
    priceRange: "180k - 250k",
    badge: "HOT",
    platform: "Shopee",
    affiliateUrl: "https://shopee.vn/",
    gender: "female",
    categoryIds: ["love", "anniversary", "womens_day"],
  },
  {
    name: { vi: "Ví Da Nam Khắc Tên", en: "Engraved Leather Wallet" },
    description: { vi: "", en: "" },
    imageUrl: "https://down-vn.img.susercontent.com/file/vn-11134207-7r98o-lt3t8a1k7b9a3h",
    priceRange: "350k - 500k",
    badge: "SPECIAL",
    platform: "Shopee",
    affiliateUrl: "https://shopee.vn/",
    gender: "male",
    categoryIds: ["birthday", "anniversary"],
  },
  {
    name: { vi: "Máy Phun Sương Mini", en: "Mini Humidifier" },
    description: { vi: "", en: "" },
    imageUrl: "https://down-vn.img.susercontent.com/file/vn-11134207-7r98o-lt3t9b2l8c0b4i",
    priceRange: "90k - 150k",
    badge: "SALE",
    platform: "Lazada",
    affiliateUrl: "https://lazada.vn/",
    gender: "unisex",
    categoryIds: ["birthday", "holiday"],
  },
  {
    name: { vi: "Hộp Quà Bánh Trung Thu", en: "Mooncake Gift Box" },
    description: { vi: "", en: "" },
    imageUrl: "https://down-vn.img.susercontent.com/file/vn-11134207-7r98o-lt3t0c3m9d1c5j",
    priceRange: "400k - 800k",
    badge: "HOT",
    platform: "Tiki",
    affiliateUrl: "https://tiki.vn/",
    gender: "unisex",
    categoryIds: ["mid_autumn", "holiday"],
  },
  {
    name: { vi: "Balo Vải Canvas", en: "Canvas Backpack" },
    description: { vi: "", en: "" },
    imageUrl: "https://down-vn.img.susercontent.com/file/vn-11134207-7r98o-lt3t1d4n0e2d6k",
    priceRange: "200k - 350k",
    badge: "",
    platform: "Shopee",
    affiliateUrl: "https://shopee.vn/",
    gender: "unisex",
    categoryIds: ["birthday"],
  }
];

function toFirestore(obj) {
  const result = {};
  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === 'string') result[key] = { stringValue: value };
    else if (typeof value === 'number') result[key] = { integerValue: value.toString() };
    else if (Array.isArray(value)) result[key] = { arrayValue: { values: value.map(v => ({ stringValue: v })) } };
    else if (typeof value === 'object') result[key] = { mapValue: { fields: toFirestore(value) } };
  }
  return result;
}

async function run() {
  let success = 0;
  for (let i = 0; i < sampleGifts.length; i++) {
    const gift = sampleGifts[i];
    gift.order = Date.now() + i;
    const body = { fields: toFirestore(gift) };
    
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body)
      });
      if (res.ok) success++;
      else console.error(await res.text());
    } catch (e) {
      console.error(e);
    }
  }
  console.log(`Successfully inserted ${success} gifts.`);
}
run();
