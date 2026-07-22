



/**
 * Lấy toàn bộ ngày lễ, tính số ngày còn lại và sắp xếp gần nhất lên đầu.
 */
function getUpcomingOccasions() {
    return specialOccasions
        .map(occ => ({ ...occ, daysLeft: daysUntil(occ.month, occ.day) }))
        .sort((a, b) => a.daysLeft - b.daysLeft);
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

// Render banners ngày lễ đặc biệt (hiển thị tất cả, gần nhất lên đầu)
function renderOccasions() {
    const container = document.getElementById('occasion-list');
    container.innerHTML = '';

    const occasions = getUpcomingOccasions();
    if (occasions.length === 0) return;

    // Chỉ lấy ngày lễ gần nhất
    const occ = occasions[0];

    const btn = document.createElement('button');
    btn.className = 'occasion-chip w-full flex items-center gap-2 px-3 py-1.5 rounded-xl outline-none text-white';
    btn.style.background = occ.gradient;

    const isToday = occ.daysLeft === 0;

    btn.innerHTML = `
        <!-- LEFT: Emoji + info một hàng -->
        <span class="text-base flex-shrink-0">${occ.emoji}</span>
        <div class="flex flex-col items-start leading-none flex-1 min-w-0">
            <div class="flex items-baseline gap-1.5 flex-wrap">
                <span class="text-[12px] font-extrabold truncate">${occ.name}</span>
                <span class="text-[9px] opacity-65 font-medium">${occ.dateLabel}</span>
            </div>
            <span class="cta-blink text-[8px] font-bold mt-0.5"><i class="fa-solid fa-hand-pointer mr-0.5"></i>Nhấn để xem quà tặng</span>
        </div>
        <!-- RIGHT: Số ngày -->
        <div class="flex-shrink-0 flex items-center gap-1 bg-black/20 rounded-lg px-2 py-1">
            <span class="text-[15px] font-black tabular-nums leading-none">${isToday ? '🎉' : occ.daysLeft}</span>
            ${isToday ? '' : '<span class="text-[8px] font-bold opacity-70 leading-none">ngày</span>'}
        </div>
    `;

    btn.addEventListener('click', () => {
        window.location.href = `${occ.id}.html`;
    });

    container.appendChild(btn);
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
