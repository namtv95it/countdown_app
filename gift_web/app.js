



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

    const occasions = getUpcomingOccasions().slice(0, 5); // Hiển thị tối đa 5 sự kiện
    if (occasions.length === 0) return;

    const dotsContainer = document.getElementById('occasion-dots');
    dotsContainer.innerHTML = '';

    occasions.forEach((occ, index) => {
        const btn = document.createElement('button');
        // Sử dụng w-full để cố định chiều rộng bằng 100% container, không bị giãn nở
        btn.className = 'occasion-chip w-full max-w-full flex-shrink-0 snap-center flex items-center gap-3 px-4 py-3 rounded-2xl outline-none text-white shadow-sm';
        btn.style.background = occ.gradient;

        const isToday = occ.daysLeft === 0;

        btn.innerHTML = `
            <!-- LEFT: Emoji + info -->
            <span class="text-3xl flex-shrink-0">${occ.emoji}</span>
            <div class="flex flex-col items-start leading-tight flex-1 min-w-0 gap-0.5">
                <span class="text-[16px] font-extrabold truncate w-full text-left">${occ.name}</span>
                <span class="text-[12px] opacity-90 font-medium w-full text-left">${occ.dateLabel}</span>
                <span class="cta-blink text-[10px] font-bold mt-0.5 text-white/90"><i class="fa-solid fa-gift mr-1"></i>Nhấn để xem quà tặng</span>
            </div>
            <!-- RIGHT: Số ngày -->
            <div class="flex-shrink-0 flex flex-col items-start justify-center bg-black/25 rounded-xl px-3 py-1.5 min-w-[68px]">
                ${isToday ? '' : '<span class="text-[9px] font-bold opacity-80 uppercase tracking-wider mb-0.5 w-full text-left">Còn</span>'}
                <div class="flex items-baseline gap-0.5">
                    <span class="text-[24px] font-black tabular-nums leading-none">${isToday ? '🎉' : occ.daysLeft}</span>
                    ${isToday ? '' : '<span class="text-[10px] font-bold opacity-80">ngày</span>'}
                </div>
            </div>
        `;

        btn.onclick = () => {
            window.location.href = `tet_trung_thu.html?occasion=${occ.id}`;
        };

        container.appendChild(btn);

        // Tạo dot tương ứng
        const dot = document.createElement('div');
        dot.className = `w-1.5 h-1.5 rounded-full transition-all duration-300 ${index === 0 ? 'bg-white w-4' : 'bg-white/30'}`;
        dotsContainer.appendChild(dot);
    });

    // Cập nhật dot khi cuộn
    container.addEventListener('scroll', () => {
        const scrollLeft = container.scrollLeft;
        const itemWidth = container.clientWidth + 12; // 12px for gap-3
        const activeIndex = Math.round(scrollLeft / itemWidth);
        
        const dots = dotsContainer.children;
        for (let i = 0; i < dots.length; i++) {
            if (i === activeIndex) {
                dots[i].className = 'w-4 h-1.5 rounded-full transition-all duration-300 bg-white';
            } else {
                dots[i].className = 'w-1.5 h-1.5 rounded-full transition-all duration-300 bg-white/30';
            }
        }
    });

    // Tự động chuyển banner sau mỗi 6 giây
    if (window.occasionAutoScroll) clearInterval(window.occasionAutoScroll);
    window.occasionAutoScroll = setInterval(() => {
        const itemWidth = container.clientWidth + 12; // 12px for gap-3
        let nextIndex = Math.round(container.scrollLeft / itemWidth) + 1;
        
        if (nextIndex >= dotsContainer.children.length) {
            nextIndex = 0;
        }
        
        container.scrollTo({
            left: nextIndex * itemWidth,
            behavior: 'smooth'
        });
    }, 6000);
}



// Render danh sách danh mục
function renderCategories() {
    const container = document.getElementById('category-list');
    container.innerHTML = '';

    categories.forEach(cat => {
        const btn = document.createElement('button');
        const isActive = currentCategory === cat.id;
        btn.className = `category-chip px-4 py-2 rounded-full flex items-center gap-2 whitespace-nowrap outline-none ${isActive ? 'active text-white font-bold' : 'text-white/70 font-semibold'}`;
        
        if (isActive) {
            if (cat.id === 'all') {
                const allColor = '#7C3AED';
                const allColorRgb = hexToRgb(allColor);
                btn.style.background = `linear-gradient(135deg, ${allColor}, rgba(${allColorRgb}, 0.6))`;
            } else {
                const catColorRgb = hexToRgb(cat.color || '#FACC15');
                btn.style.background = `linear-gradient(135deg, ${cat.color || '#FACC15'}, rgba(${catColorRgb}, 0.6))`;
            }
        }
        
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
        : products.filter(p => p.categoryIds && p.categoryIds.includes(currentCategory));

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
        const cat = categories.find(c => product.categoryIds && product.categoryIds.includes(c.id)) || categories[1];
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
                <div class="absolute top-2 right-2 px-2 h-5 bg-gradient-to-r from-yellow-500 to-amber-600 rounded-md shadow-lg flex items-center justify-center">
                    <span class="text-[10px] font-bold text-white tracking-wider uppercase leading-none mt-[1px]">⭐ Hot</span>
                </div>
                ` : ''}
            </div>

            <!-- Info Section -->
            <div class="p-3 flex flex-col flex-grow">
                <h3 class="text-sm font-bold text-white line-clamp-2 mb-3">${product.name}</h3>
                
                <div class="mt-auto">
                    <div class="text-sm font-black mb-2" style="color: ${cat.color || '#FACC15'}">${product.priceRange}</div>
                    <div class="w-full py-1.5 rounded-lg border flex items-center justify-center gap-1.5 transition-colors" 
                         style="background-color: rgba(${catColorRgb}, 0.18); border-color: rgba(${catColorRgb}, 0.4)">
                        <i class="${product.platform === 'Tiktok Shop' ? 'fa-brands fa-tiktok' : 'fa-solid fa-bag-shopping'} text-[11px]" style="color: ${cat.color}"></i>
                        <span class="text-xs font-bold" style="color: ${cat.color}">${product.platform || 'Xem ngay'}</span>
                    </div>
                </div>
            </div>
        `;
        
        grid.appendChild(card);
    });
}
