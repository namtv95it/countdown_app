// Ngôn ngữ hiện tại (được set bởi app.js khi đọc URL param)
let currentLang = 'vi';

// Helper lấy text theo ngôn ngữ
function L(obj) {
    return (obj && obj[currentLang]) ? obj[currentLang] : (obj && obj['vi']) ? obj['vi'] : '';
}

// Dữ liệu danh mục
const categories = [
    { id: 'all',        name: { vi: 'Tất cả',    en: 'All'         }, emoji: '' },
    { id: 'birthday',   name: { vi: 'Sinh nhật',  en: 'Birthday'    }, emoji: '🎂', color: '#3B82F6' },
    { id: 'love',       name: { vi: 'Tình yêu',   en: 'Love'        }, emoji: '❤️', color: '#EC4899' },
    { id: 'anniversary',name: { vi: 'Kỷ niệm',    en: 'Anniversary' }, emoji: '💍', color: '#8B5CF6' },
    { id: 'holiday',    name: { vi: 'Lễ tết',     en: 'Holiday'     }, emoji: '🎆', color: '#F59E0B' },
    { id: 'mid_autumn', name: { vi: 'Trung Thu',  en: 'Mid-Autumn'  }, emoji: '🥮', color: '#D97706' },
];

// Dữ liệu sản phẩm
const products = [
    {
        id: '8',
        categoryIds: ['mid_autumn', 'holiday'],
        name: { vi: 'Hộp Bánh Trung Thu Trứng Chảy', en: 'Molten Egg Yolk Mooncake Box' },
        description: { vi: 'Set 6 bánh trung thu trứng muối chảy thượng hạng, vỏ bánh mềm mịn.', en: 'Set of 6 premium salted egg yolk mooncakes with soft, smooth skin.' },
        priceRange: '350k - 600k',
        imageUrl: 'https://images.unsplash.com/photo-1601002360216-563b7e734c26?w=400&q=80',
        isPopular: true,
        platform: 'Tiktok Shop',
        affiliateUrl: 'https://shopee.vn/search?keyword=b%C3%A1nh%20trung%20thu'
    },
    {
        id: '7',
        categoryIds: ['anniversary', 'love'],
        name: { vi: 'Đồng Hồ Đôi Daniel Wellington', en: 'Daniel Wellington Couple Watch Set' },
        description: { vi: 'Set đồng hồ nam nữ chính hãng.', en: 'Authentic men\'s and women\'s watch set.' },
        priceRange: '3tr - 5tr',
        imageUrl: 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=400&q=80',
        isPopular: true,
        platform: 'Shopee',
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '6',
        categoryIds: ['birthday', 'children_day'],
        name: { vi: 'Gấu Bông Teddy Khổng Lồ', en: 'Giant Teddy Bear' },
        description: { vi: 'Gấu bông size lớn 1m5 siêu mềm mịn.', en: '1.5m giant super soft and fluffy teddy bear.' },
        priceRange: '400k - 700k',
        imageUrl: 'https://images.unsplash.com/photo-1559454403-b8fb88521f11?w=400&q=80',
        isPopular: false,
        platform: 'Shopee',
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '5',
        categoryIds: ['holiday'],
        name: { vi: 'Giỏ Quà Tết Sum Vầy', en: 'Tet Family Reunion Gift Basket' },
        description: { vi: 'Giỏ quà bao gồm rượu vang và bánh kẹo nhập khẩu.', en: 'Gift basket with imported wine and assorted confectioneries.' },
        priceRange: '800k - 1.5tr',
        imageUrl: 'https://images.unsplash.com/photo-1545239351-ef35f43d514b?w=400&q=80',
        isPopular: true,
        platform: 'Shopee',
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '4',
        order: 1,
        categoryIds: ['love', 'birthday', 'womens_day'],
        name: { vi: 'Set Son MAC & Nước Hoa', en: 'MAC Lipstick & Perfume Set' },
        description: { vi: 'Set quà cao cấp dành cho phái đẹp.', en: 'Premium gift set for women.' },
        priceRange: '1.2tr - 2tr',
        imageUrl: 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&q=80',
        isPopular: true,
        platform: 'Shopee',
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '3',
        categoryIds: ['anniversary', 'love'],
        name: { vi: 'Dây Chuyền Bạc Cỏ 4 Lá', en: 'Four-Leaf Clover Silver Necklace' },
        description: { vi: 'Trang sức bạc S925 cao cấp mang lại may mắn.', en: 'Premium S925 silver jewelry bringing good luck.' },
        priceRange: '450k - 800k',
        imageUrl: 'https://images.unsplash.com/photo-1599643478514-4a410f0814a0?w=400&q=80',
        isPopular: false,
        platform: 'Shopee',
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '2',
        order: 2,
        categoryIds: ['love', 'anniversary', 'womens_day'],
        name: { vi: 'Bó Hoa Hồng Sáp Thơm', en: 'Scented Wax Rose Bouquet' },
        description: { vi: 'Bó 99 đóa hoa hồng sáp cao cấp, lưu hương lâu.', en: '99 premium scented wax roses with long-lasting fragrance.' },
        priceRange: '300k - 550k',
        imageUrl: 'https://images.unsplash.com/photo-1563241527-3004b7be0ffd?w=400&q=80',
        isPopular: true,
        platform: 'Shopee',
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '1',
        categoryIds: ['birthday', 'love'],
        name: { vi: 'Hộp Quà Bất Ngờ Kèm Bánh', en: 'Surprise Gift Box with Cake' },
        description: { vi: 'Set quà tặng sinh nhật đặc biệt với hộp nhạc và bánh kem nhỏ.', en: 'Special birthday gift set with a music box and mini cream cake.' },
        priceRange: '250k - 500k',
        imageUrl: 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=400&q=80',
        isPopular: true,
        platform: 'Shopee',
        affiliateUrl: 'https://shopee.vn'
    }
];

// Sắp xếp sản phẩm: Ưu tiên 'order' (nhỏ đến lớn), sau đó đến 'id' (lớn đến nhỏ)
products.sort((a, b) => {
    const orderA = a.order !== undefined ? a.order : 99999;
    const orderB = b.order !== undefined ? b.order : 99999;
    if (orderA !== orderB) return orderA - orderB;
    return parseInt(b.id) - parseInt(a.id);
});

// Các ngày lễ trong năm (month: 1-indexed)
const specialOccasions = [
    { id: 'valentine',      name: { vi: 'Valentine',               en: 'Valentine\'s Day'       }, dateLabel: { vi: '14 tháng 2',   en: 'Feb 14'  }, emoji: '💝', month: 2,  day: 14, gradient: 'linear-gradient(135deg, #EC4899, #BE185D)', categoryId: 'love' },
    { id: 'womens_day',     name: { vi: 'Ngày Quốc tế Phụ nữ',    en: 'Int\'l Women\'s Day'    }, dateLabel: { vi: '8 tháng 3',    en: 'Mar 8'   }, emoji: '🌸', month: 3,  day: 8,  gradient: 'linear-gradient(135deg, #F472B6, #A855F7)', categoryId: 'love' },
    { id: 'mothers_day',    name: { vi: 'Ngày của Mẹ',             en: 'Mother\'s Day'          }, dateLabel: { vi: '12 tháng 5',   en: 'May 12'  }, emoji: '💐', month: 5,  day: 12, gradient: 'linear-gradient(135deg, #F59E0B, #EF4444)', categoryId: 'birthday' },
    { id: 'children_day',   name: { vi: 'Tết Thiếu nhi',           en: 'Children\'s Day'        }, dateLabel: { vi: '1 tháng 6',    en: 'Jun 1'   }, emoji: '🎈', month: 6,  day: 1,  gradient: 'linear-gradient(135deg, #3B82F6, #06B6D4)', categoryId: 'birthday' },
    { id: 'fathers_day',    name: { vi: 'Ngày của Bố',             en: 'Father\'s Day'          }, dateLabel: { vi: '21 tháng 6',   en: 'Jun 21'  }, emoji: '👔', month: 6,  day: 21, gradient: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', categoryId: 'birthday' },
    { id: 'tet_trung_thu',  name: { vi: 'Tết Trung Thu',           en: 'Mid-Autumn Festival'   }, dateLabel: { vi: '17 tháng 9',   en: 'Sep 17'  }, emoji: '🥮', month: 9,  day: 17, gradient: 'linear-gradient(135deg, #F59E0B, #D97706)', categoryId: 'mid_autumn' },
    { id: 'womens_day_vn',  name: { vi: 'Ngày Phụ nữ Việt Nam',   en: 'Vietnamese Women\'s Day' }, dateLabel: { vi: '20 tháng 10', en: 'Oct 20'  }, emoji: '🌺', month: 10, day: 20, gradient: 'linear-gradient(135deg, #EC4899, #7C3AED)', categoryId: 'love' },
    { id: 'teachers_day',   name: { vi: 'Ngày Nhà giáo VN',        en: 'Teachers\' Day'         }, dateLabel: { vi: '20 tháng 11', en: 'Nov 20'  }, emoji: '📚', month: 11, day: 20, gradient: 'linear-gradient(135deg, #10B981, #0EA5E9)', categoryId: 'birthday' },
    { id: 'christmas',      name: { vi: 'Giáng Sinh',              en: 'Christmas'              }, dateLabel: { vi: '25 tháng 12', en: 'Dec 25'  }, emoji: '🎄', month: 12, day: 25, gradient: 'linear-gradient(135deg, #EF4444, #16A34A)', categoryId: 'holiday' },
    { id: 'noel_eve',       name: { vi: 'Tất niên',                en: 'New Year\'s Eve'        }, dateLabel: { vi: '31 tháng 12', en: 'Dec 31'  }, emoji: '🥂', month: 12, day: 31, gradient: 'linear-gradient(135deg, #7C3AED, #0EA5E9)', categoryId: 'holiday' },
    { id: 'new_year',       name: { vi: 'Năm Mới',                 en: 'New Year'               }, dateLabel: { vi: '1 tháng 1',   en: 'Jan 1'   }, emoji: '🎆', month: 1,  day: 1,  gradient: 'linear-gradient(135deg, #7C3AED, #EC4899)', categoryId: 'holiday' },
    { id: 'tet',            name: { vi: 'Tết Nguyên Đán',          en: 'Lunar New Year'         }, dateLabel: { vi: '29 tháng 1',  en: 'Jan 29'  }, emoji: '🧧', month: 1,  day: 29, gradient: 'linear-gradient(135deg, #EF4444, #F59E0B)', categoryId: 'holiday' },
];

// UI string translations
const uiStrings = {
    vi: {
        notFound: 'Không tìm thấy sản phẩm',
        notFoundSub: 'Hãy thử chọn một danh mục khác.',
        tapToSeeGifts: 'Nhấn để xem quà tặng',
        daysLeft: 'Còn',
        days: 'ngày',
        viewNow: 'Xem ngay',
        hot: '⭐ HOT',
    },
    en: {
        notFound: 'No products found',
        notFoundSub: 'Try selecting a different category.',
        tapToSeeGifts: 'Tap to see gift ideas',
        daysLeft: '',
        days: 'days left',
        viewNow: 'View Now',
        hot: '⭐ HOT',
    }
};

function ui(key) {
    const lang = currentLang;
    return (uiStrings[lang] && uiStrings[lang][key]) ? uiStrings[lang][key] : (uiStrings['vi'][key] || key);
}

/**
 * Tính số ngày còn lại đến ngày lễ (luôn lấy ngày gần nhất trong tương lai).
 */
function daysUntil(month, day) {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    let target = new Date(today.getFullYear(), month - 1, day);
    if (target < today) {
        target = new Date(today.getFullYear() + 1, month - 1, day);
    }
    return Math.round((target - today) / (1000 * 60 * 60 * 24));
}
