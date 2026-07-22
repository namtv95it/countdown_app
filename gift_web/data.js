// Dữ liệu danh mục
const categories = [
    { id: 'all', name: 'Tất cả', emoji: '' },
    { id: 'birthday', name: 'Sinh nhật', emoji: '🎂', color: '#3B82F6' },
    { id: 'love', name: 'Tình yêu', emoji: '❤️', color: '#EC4899' },
    { id: 'anniversary', name: 'Kỷ niệm', emoji: '💍', color: '#8B5CF6' },
    { id: 'holiday', name: 'Lễ tết', emoji: '🎆', color: '#F59E0B' },
    { id: 'mid_autumn', name: 'Trung Thu', emoji: '🥮', color: '#D97706' },
];

// Dữ liệu sản phẩm mẫu
const products = [
    {
        id: '1',
        categoryIds: ['birthday', 'love'],
        name: 'Hộp Quà Bất Ngờ Kèm Bánh',
        description: 'Set quà tặng sinh nhật đặc biệt với hộp nhạc và bánh kem nhỏ.',
        priceRange: '250k - 500k',
        imageUrl: 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=400&q=80',
        isPopular: true,
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '2',
        categoryIds: ['love', 'anniversary', 'womens_day'],
        name: 'Bó Hoa Hồng Sáp Thơm',
        description: 'Bó 99 đóa hoa hồng sáp cao cấp, lưu hương lâu.',
        priceRange: '300k - 550k',
        imageUrl: 'https://images.unsplash.com/photo-1563241527-3004b7be0ffd?w=400&q=80',
        isPopular: true,
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '3',
        categoryIds: ['anniversary', 'love'],
        name: 'Dây Chuyền Bạc Cỏ 4 Lá',
        description: 'Trang sức bạc S925 cao cấp mang lại may mắn.',
        priceRange: '450k - 800k',
        imageUrl: 'https://images.unsplash.com/photo-1599643478514-4a410f0814a0?w=400&q=80',
        isPopular: false,
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '4',
        categoryIds: ['love', 'birthday', 'womens_day'],
        name: 'Set Son MAC & Nước Hoa',
        description: 'Set quà cao cấp dành cho phái đẹp.',
        priceRange: '1.2tr - 2tr',
        imageUrl: 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&q=80',
        isPopular: true,
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '5',
        categoryIds: ['holiday'],
        name: 'Giỏ Quà Tết Sum Vầy',
        description: 'Giỏ quà bao gồm rượu vang và bánh kẹo nhập khẩu.',
        priceRange: '800k - 1.5tr',
        imageUrl: 'https://images.unsplash.com/photo-1545239351-ef35f43d514b?w=400&q=80',
        isPopular: true,
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '6',
        categoryIds: ['birthday', 'children_day'],
        name: 'Gấu Bông Teddy Khổng Lồ',
        description: 'Gấu bông size lớn 1m5 siêu mềm mịn.',
        priceRange: '400k - 700k',
        imageUrl: 'https://images.unsplash.com/photo-1559454403-b8fb88521f11?w=400&q=80',
        isPopular: false,
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '7',
        categoryIds: ['anniversary', 'love'],
        name: 'Đồng Hồ Đôi Daniel Wellington',
        description: 'Set đồng hồ nam nữ chính hãng.',
        priceRange: '3tr - 5tr',
        imageUrl: 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=400&q=80',
        isPopular: true,
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '8',
        categoryIds: ['mid_autumn', 'holiday'],
        name: 'Hộp Bánh Trung Thu Trứng Chảy',
        description: 'Set 6 bánh trung thu trứng muối chảy thượng hạng, vỏ bánh mềm mịn.',
        priceRange: '350k - 600k',
        imageUrl: 'https://images.unsplash.com/photo-1601002360216-563b7e734c26?w=400&q=80',
        isPopular: true,
        affiliateUrl: 'https://shopee.vn/search?keyword=b%C3%A1nh%20trung%20thu'
    }
];

// Các ngày lễ trong năm (month: 1-indexed)
const specialOccasions = [
    { id: 'valentine', name: "Valentine", dateLabel: "14 tháng 2", emoji: "💝", month: 2, day: 14, gradient: 'linear-gradient(135deg, #EC4899, #BE185D)', categoryId: 'love' },
    { id: 'womens_day', name: "Ngày Quốc tế Phụ nữ", dateLabel: "8 tháng 3", emoji: "🌸", month: 3, day: 8, gradient: 'linear-gradient(135deg, #F472B6, #A855F7)', categoryId: 'love' },
    { id: 'mothers_day', name: "Ngày của Mẹ", dateLabel: "12 tháng 5", emoji: "💐", month: 5, day: 12, gradient: 'linear-gradient(135deg, #F59E0B, #EF4444)', categoryId: 'birthday' },
    { id: 'children_day', name: "Tết Thiếu nhi", dateLabel: "1 tháng 6", emoji: "🎈", month: 6, day: 1, gradient: 'linear-gradient(135deg, #3B82F6, #06B6D4)', categoryId: 'birthday' },
    { id: 'fathers_day', name: "Ngày của Bố", dateLabel: "21 tháng 6", emoji: "👔", month: 6, day: 21, gradient: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', categoryId: 'birthday' },
    { id: 'tet_trung_thu', name: "Tết Trung Thu", dateLabel: "17 tháng 9", emoji: "🥮", month: 9, day: 17, gradient: 'linear-gradient(135deg, #F59E0B, #D97706)', categoryId: 'mid_autumn' },
    { id: 'womens_day_vn', name: "Ngày Phụ nữ Việt Nam", dateLabel: "20 tháng 10", emoji: "🌺", month: 10, day: 20, gradient: 'linear-gradient(135deg, #EC4899, #7C3AED)', categoryId: 'love' },
    { id: 'teachers_day', name: "Ngày Nhà giáo VN", dateLabel: "20 tháng 11", emoji: "📚", month: 11, day: 20, gradient: 'linear-gradient(135deg, #10B981, #0EA5E9)', categoryId: 'birthday' },
    { id: 'christmas', name: "Giáng Sinh", dateLabel: "25 tháng 12", emoji: "🎄", month: 12, day: 25, gradient: 'linear-gradient(135deg, #EF4444, #16A34A)', categoryId: 'holiday' },
    { id: 'noel_eve', name: "Tất niên", dateLabel: "31 tháng 12", emoji: "🥂", month: 12, day: 31, gradient: 'linear-gradient(135deg, #7C3AED, #0EA5E9)', categoryId: 'holiday' },
    { id: 'new_year', name: "Năm Mới", dateLabel: "1 tháng 1", emoji: "🎆", month: 1, day: 1, gradient: 'linear-gradient(135deg, #7C3AED, #EC4899)', categoryId: 'holiday' },
    { id: 'tet', name: "Tết Nguyên Đán", dateLabel: "29 tháng 1", emoji: "🧧", month: 1, day: 29, gradient: 'linear-gradient(135deg, #EF4444, #F59E0B)', categoryId: 'holiday' },
];

/**
 * Tính số ngày còn lại đến ngày lễ (luôn lấy ngày gần nhất trong tương lai).
 */
function daysUntil(month, day) {
    const now = new Date();
    // Đặt thời gian về đầu ngày để tính chính xác
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    let target = new Date(today.getFullYear(), month - 1, day);
    if (target < today) {
        // Ngày lễ năm nay đã qua → lấy năm sau
        target = new Date(today.getFullYear() + 1, month - 1, day);
    }
    return Math.round((target - today) / (1000 * 60 * 60 * 24));
}
