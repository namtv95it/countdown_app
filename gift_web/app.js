// Dữ liệu danh mục
const categories = [
    { id: 'all', name: 'Tất cả', emoji: '' },
    { id: 'birthday', name: 'Sinh nhật', emoji: '🎂', color: '#3B82F6' },
    { id: 'love', name: 'Tình yêu', emoji: '❤️', color: '#EC4899' },
    { id: 'anniversary', name: 'Kỷ niệm', emoji: '💍', color: '#8B5CF6' },
    { id: 'holiday', name: 'Lễ tết', emoji: '🎆', color: '#F59E0B' },
];

// Dữ liệu sản phẩm mẫu
const products = [
    {
        id: '1',
        categoryId: 'birthday',
        name: 'Hộp Quà Bất Ngờ Kèm Bánh',
        description: 'Set quà tặng sinh nhật đặc biệt với hộp nhạc và bánh kem nhỏ.',
        priceRange: '250k - 500k',
        imageUrl: 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=400&q=80',
        isPopular: true,
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '2',
        categoryId: 'love',
        name: 'Bó Hoa Hồng Sáp Thơm',
        description: 'Bó 99 đóa hoa hồng sáp cao cấp, lưu hương lâu.',
        priceRange: '300k - 550k',
        imageUrl: 'https://images.unsplash.com/photo-1563241527-3004b7be0ffd?w=400&q=80',
        isPopular: true,
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '3',
        categoryId: 'anniversary',
        name: 'Dây Chuyền Bạc Cỏ 4 Lá',
        description: 'Trang sức bạc S925 cao cấp mang lại may mắn.',
        priceRange: '450k - 800k',
        imageUrl: 'https://images.unsplash.com/photo-1599643478514-4a410f0814a0?w=400&q=80',
        isPopular: false,
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '4',
        categoryId: 'love',
        name: 'Set Son MAC & Nước Hoa',
        description: 'Set quà cao cấp dành cho phái đẹp.',
        priceRange: '1.2tr - 2tr',
        imageUrl: 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&q=80',
        isPopular: true,
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '5',
        categoryId: 'holiday',
        name: 'Giỏ Quà Tết Sum Vầy',
        description: 'Giỏ quà bao gồm rượu vang và bánh kẹo nhập khẩu.',
        priceRange: '800k - 1.5tr',
        imageUrl: 'https://images.unsplash.com/photo-1545239351-ef35f43d514b?w=400&q=80',
        isPopular: true,
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '6',
        categoryId: 'birthday',
        name: 'Gấu Bông Teddy Khổng Lồ',
        description: 'Gấu bông size lớn 1m5 siêu mềm mịn.',
        priceRange: '400k - 700k',
        imageUrl: 'https://images.unsplash.com/photo-1559454403-b8fb88521f11?w=400&q=80',
        isPopular: false,
        affiliateUrl: 'https://shopee.vn'
    },
    {
        id: '7',
        categoryId: 'anniversary',
        name: 'Đồng Hồ Đôi Daniel Wellington',
        description: 'Set đồng hồ nam nữ chính hãng.',
        priceRange: '3tr - 5tr',
        imageUrl: 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=400&q=80',
        isPopular: true,
        affiliateUrl: 'https://shopee.vn'
    }
];

// ──────────────────────────────────────────────────────────────
// NGÀY LỄ ĐẶC BIỆT — hiển thị theo ngày hiện tại
// ──────────────────────────────────────────────────────────────

// Các ngày lễ trong năm (month: 1-indexed)
const specialOccasions = [
    { id: 'valentine', name: "Valentine 14/2", emoji: "💝", month: 2, day: 14, range: 14, gradient: 'linear-gradient(135deg, #EC4899, #BE185D)', categoryId: 'love' },
    { id: 'womens_day', name: "Ngày 8/3", emoji: "🌸", month: 3, day: 8, range: 14, gradient: 'linear-gradient(135deg, #F472B6, #A855F7)', categoryId: 'love' },
    { id: 'mothers_day', name: "Ngày của Mẹ", emoji: "💐", month: 5, day: 12, range: 14, gradient: 'linear-gradient(135deg, #F59E0B, #EF4444)', categoryId: 'birthday' },
    { id: 'children_day', name: "Tết Thiếu nhi 1/6", emoji: "🎈", month: 6, day: 1, range: 10, gradient: 'linear-gradient(135deg, #3B82F6, #06B6D4)', categoryId: 'birthday' },
    { id: 'fathers_day', name: "Ngày của Bố", emoji: "👔", month: 6, day: 21, range: 14, gradient: 'linear-gradient(135deg, #1D4ED8, #3B82F6)', categoryId: 'birthday' },
    { id: 'tet_trung_thu', name: "Tết Trung Thu", emoji: "🥮", month: 9, day: 17, range: 14, gradient: 'linear-gradient(135deg, #F59E0B, #D97706)', categoryId: 'holiday' },
    { id: 'womens_day_vn', name: "20/10", emoji: "🌺", month: 10, day: 20, range: 14, gradient: 'linear-gradient(135deg, #EC4899, #7C3AED)', categoryId: 'love' },
    { id: 'teachers_day', name: "Ngày 20/11", emoji: "📚", month: 11, day: 20, range: 14, gradient: 'linear-gradient(135deg, #10B981, #0EA5E9)', categoryId: 'birthday' },
    { id: 'christmas', name: "Giáng Sinh", emoji: "🎄", month: 12, day: 25, range: 20, gradient: 'linear-gradient(135deg, #EF4444, #16A34A)', categoryId: 'holiday' },
    { id: 'tet', name: "Tết Nguyên Đán", emoji: "🧧", month: 1, day: 29, range: 21, gradient: 'linear-gradient(135deg, #EF4444, #F59E0B)', categoryId: 'holiday' },
    { id: 'new_year', name: "Năm Mới", emoji: "🎆", month: 1, day: 1, range: 7, gradient: 'linear-gradient(135deg, #7C3AED, #EC4899)', categoryId: 'holiday' },
    { id: 'noel_eve', name: "Tất niên", emoji: "🥂", month: 12, day: 31, range: 7, gradient: 'linear-gradient(135deg, #7C3AED, #0EA5E9)', categoryId: 'holiday' },
];

/**
 * Tính số ngày còn lại đến ngày lễ.
 * Trả về số ngày (âm nếu đã qua), dương nếu còn.
 */
function daysUntil(month, day) {
    const now = new Date();
    const thisYear = new Date(now.getFullYear(), month - 1, day);
    let diff = Math.ceil((thisYear - now) / (1000 * 60 * 60 * 24));
    if (diff < -1) {
        // Thử năm sau
        const nextYear = new Date(now.getFullYear() + 1, month - 1, day);
        diff = Math.ceil((nextYear - now) / (1000 * 60 * 60 * 24));
    }
    return diff;
}

/**
 * Lấy danh sách các ngày lễ sắp đến trong vòng `range` ngày tới.
 */
function getUpcomingOccasions() {
    const upcoming = [];
    for (const occ of specialOccasions) {
        const days = daysUntil(occ.month, occ.day);
        if (days >= 0 && days <= occ.range) {
            upcoming.push({ ...occ, daysLeft: days });
        }
    }
    // Sắp xếp: ngày gần nhất lên đầu
    upcoming.sort((a, b) => a.daysLeft - b.daysLeft);
    return upcoming;
}

// Trạng thái ứng dụng
let currentCategory = 'all';

// Khởi tạo
document.addEventListener('DOMContentLoaded', () => {
    // Lấy giá trị category từ URL (VD: ?category=birthday)
    const urlParams = new URLSearchParams(window.location.search);
    const categoryParam = urlParams.get('category');
    
    // Nếu có category trong URL và hợp lệ thì gán làm category hiện tại
    if (categoryParam && categories.find(c => c.id === categoryParam)) {
        currentCategory = categoryParam;
    }

    renderOccasions();
    renderCategories();
    renderProducts();
});

// Render banners ngày lễ đặc biệt
function renderOccasions() {
    const container = document.getElementById('occasion-list');
    container.innerHTML = '';

    const upcoming = getUpcomingOccasions();
    if (upcoming.length === 0) return;

    upcoming.forEach(occ => {
        const btn = document.createElement('button');
        btn.className = 'occasion-chip flex items-center gap-2 px-4 py-2 rounded-2xl whitespace-nowrap outline-none text-white font-bold text-sm';
        btn.style.background = occ.gradient;
        btn.style.boxShadow = '0 4px 14px rgba(0,0,0,0.3)';

        const label = occ.daysLeft === 0
            ? `Hôm nay!`
            : occ.daysLeft === 1
            ? `Còn 1 ngày`
            : `Còn ${occ.daysLeft} ngày`;

        btn.innerHTML = `
            <span class="text-base">${occ.emoji}</span>
            <div class="flex flex-col items-start leading-tight">
                <span class="text-xs font-extrabold">${occ.name}</span>
                <span class="text-[10px] opacity-80">${label}</span>
            </div>
        `;

        btn.addEventListener('click', () => {
            // Lọc sản phẩm theo danh mục của ngày lễ
            currentCategory = occ.categoryId;
            renderCategories();
            renderProducts();
        });

        container.appendChild(btn);
    });
}


// Render danh sách danh mục
function renderCategories() {
    const container = document.getElementById('category-list');
    container.innerHTML = '';

    categories.forEach(cat => {
        const btn = document.createElement('button');
        btn.className = `category-chip px-4 py-2 rounded-full flex items-center gap-2 whitespace-nowrap outline-none ${currentCategory === cat.id ? 'active text-white font-bold' : 'text-white/70 font-semibold'}`;
        
        // Nội dung HTML bên trong nút
        let content = '';
        if (cat.emoji) content += `<span>${cat.emoji}</span>`;
        content += `<span>${cat.name}</span>`;
        
        btn.innerHTML = content;
        
        btn.onclick = () => {
            currentCategory = cat.id;
            renderCategories();
            renderProducts();
        };

        container.appendChild(btn);
    });
}

// Convert hex to rgb string for rgba
function hexToRgb(hex) {
    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? 
        `${parseInt(result[1], 16)}, ${parseInt(result[2], 16)}, ${parseInt(result[3], 16)}` : 
        '124, 58, 237'; // default brand purple
}

// Render lưới sản phẩm
function renderProducts() {
    const grid = document.getElementById('product-grid');
    const emptyState = document.getElementById('empty-state');
    
    grid.innerHTML = '';
    
    // Lọc sản phẩm
    const filteredProducts = currentCategory === 'all' 
        ? products 
        : products.filter(p => p.categoryId === currentCategory);

    // Hiển thị trạng thái rỗng nếu không có sản phẩm
    if (filteredProducts.length === 0) {
        grid.classList.add('hidden');
        emptyState.classList.remove('hidden');
        emptyState.classList.add('flex');
        return;
    }

    grid.classList.remove('hidden');
    emptyState.classList.add('hidden');
    emptyState.classList.remove('flex');

    // Thêm các thẻ sản phẩm
    filteredProducts.forEach(product => {
        const cat = categories.find(c => c.id === product.categoryId) || categories[1];
        const catColorRgb = hexToRgb(cat.color || '#7C3AED');

        const card = document.createElement('a');
        card.href = product.affiliateUrl;
        card.target = '_blank';
        card.rel = 'noopener noreferrer';
        card.className = 'product-card glass rounded-2xl overflow-hidden flex flex-col relative block';

        card.innerHTML = `
            <!-- Image Hero Section -->
            <div class="h-28 w-full relative overflow-hidden" style="background-color: rgba(${catColorRgb}, 0.15)">
                <img src="${product.imageUrl}" alt="${product.name}" class="w-full h-full object-cover">
                ${product.isPopular ? `
                <div class="absolute top-2 right-2 px-2 py-1 bg-gradient-to-r from-yellow-500 to-amber-600 rounded-md shadow-lg">
                    <span class="text-[10px] font-bold text-white tracking-wider uppercase">⭐ Hot</span>
                </div>
                ` : ''}
            </div>

            <!-- Info Section -->
            <div class="p-3 flex flex-col flex-grow">
                <h3 class="text-sm font-bold text-white line-clamp-2 mb-1">${product.name}</h3>
                <p class="text-[11px] text-white/50 line-clamp-2 leading-relaxed mb-3">${product.description}</p>
                
                <div class="mt-auto">
                    <div class="text-xs font-bold mb-2" style="color: ${cat.color || '#FACC15'}">${product.priceRange}</div>
                    <div class="w-full py-1.5 rounded-lg border flex items-center justify-center gap-1 transition-colors" 
                         style="background-color: rgba(${catColorRgb}, 0.18); border-color: rgba(${catColorRgb}, 0.4)">
                        <span class="text-xs font-bold" style="color: ${cat.color}">Xem ngay</span>
                        <i class="fa-solid fa-arrow-up-right-from-square text-[10px]" style="color: ${cat.color}"></i>
                    </div>
                </div>
            </div>
        `;
        
        grid.appendChild(card);
    });
}
