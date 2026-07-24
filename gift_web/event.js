document.addEventListener('DOMContentLoaded', () => {
    // Đọc lang từ URL params
    const urlParams = new URLSearchParams(window.location.search);
    const langParam = urlParams.get('lang');
    if (langParam === 'en' || langParam === 'vi') {
        currentLang = langParam;
    }
    document.documentElement.lang = currentLang;

    let pathname = window.location.pathname;
    let eventId = pathname.substring(pathname.lastIndexOf('/') + 1).replace('.html', '');

    const event = specialOccasions.find(occ => occ.id === eventId);
    
    if (!event) {
        document.getElementById('event-title').innerText = '404';
        document.getElementById('event-banner').style.display = 'none';
        document.getElementById('empty-state').classList.remove('hidden');
        document.getElementById('empty-state').classList.add('flex');
        return;
    }

    // Cập nhật thông tin sự kiện
    const eventName = L(event.name);
    document.title = eventName + (currentLang === 'en' ? ' - Gift Ideas' : ' - Gợi Ý Quà Tặng');
    document.getElementById('event-title').innerText = eventName;
    document.getElementById('event-emoji').innerText = event.emoji;
    document.getElementById('event-name').innerText = eventName;
    
    // Động tính toán dateLabel
    let dateLabel = '';
    if (currentLang === 'vi') {
        dateLabel = `${event.day} tháng ${event.month}`;
    } else {
        const enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const monthStr = (event.month >= 1 && event.month <= 12) ? enMonths[event.month - 1] : 'Jan';
        dateLabel = `${monthStr} ${event.day}`;
    }
    document.getElementById('event-date').innerText = dateLabel;
    
    // Cập nhật banner background
    document.getElementById('event-banner').style.background = event.gradient;

    // Tính toán số ngày
    const daysLeft = daysUntil(event.month, event.day);

    // Tính toán Next / Prev Sự kiện
    const upcomingOccasions = specialOccasions
        .map(occ => ({ ...occ, daysLeft: daysUntil(occ.month, occ.day) }))
        .sort((a, b) => a.daysLeft - b.daysLeft);

    const currentIndex = upcomingOccasions.findIndex(occ => occ.id === event.id);
    let prevEventId = null;
    let nextEventId = null;

    if (currentIndex !== -1) {
        prevEventId = currentIndex > 0 
            ? upcomingOccasions[currentIndex - 1].id 
            : upcomingOccasions[upcomingOccasions.length - 1].id;
            
        nextEventId = currentIndex < upcomingOccasions.length - 1 
            ? upcomingOccasions[currentIndex + 1].id 
            : upcomingOccasions[0].id;
    }

    // Thêm nút Next / Prev vào Header
    const headerContainer = document.querySelector('#event-header .container');
    if (headerContainer && nextEventId && prevEventId) {
        const spacer = headerContainer.lastElementChild;
        if (spacer && spacer.tagName === 'DIV') {
            spacer.className = "flex items-center gap-2 justify-end min-w-[72px]";
            spacer.innerHTML = `
                <a href="${prevEventId}.html?lang=${currentLang}" class="w-8 h-8 flex items-center justify-center rounded-full bg-white/25 hover:bg-white/40 transition text-white" title="Sự kiện trước">
                    <i class="fa-solid fa-angle-left"></i>
                </a>
                <a href="${nextEventId}.html?lang=${currentLang}" class="w-8 h-8 flex items-center justify-center rounded-full bg-white/25 hover:bg-white/40 transition text-white" title="Sự kiện tiếp theo">
                    <i class="fa-solid fa-angle-right"></i>
                </a>
            `;
            
            // Điều chỉnh nút back bên trái để tiêu đề ở giữa không bị lệch
            const leftBtn = headerContainer.firstElementChild;
            if (leftBtn && leftBtn.tagName === 'BUTTON') {
                leftBtn.onclick = () => { window.location.href = 'index.html?lang=' + currentLang; };
                leftBtn.innerHTML = '<i class="fa-solid fa-house"></i>';
                
                const leftWrapper = document.createElement('div');
                leftWrapper.className = "min-w-[72px] flex items-center justify-start";
                leftBtn.parentNode.insertBefore(leftWrapper, leftBtn);
                leftWrapper.appendChild(leftBtn);
            }
        }
    }
    
    const countdownText = document.getElementById('event-countdown-text');
    if (daysLeft === 0) {
        countdownText.innerText = '🎉 ' + (currentLang === 'en' ? 'Today is the day!' : 'Hôm nay là ngày lễ!');
    } else {
        countdownText.innerText = (currentLang === 'en' ? `${daysLeft} days left` : `Chỉ còn ${daysLeft} ngày nữa`);
    }

    // Lọc sản phẩm theo danh mục của sự kiện
    let eventProducts = products.filter(p => p.occasionIds && p.occasionIds.includes(event.id));
    if (eventProducts.length === 0) {
        eventProducts = products.filter(p => p.categoryIds && p.categoryIds.includes(event.categoryId));
    }
    
    document.getElementById('product-count').innerText = `${eventProducts.length} món`;

    const grid = document.getElementById('product-grid');
    const emptyState = document.getElementById('empty-state');
    grid.innerHTML = '';

    if (eventProducts.length === 0) {
        grid.style.display = 'none';
        emptyState.classList.remove('hidden');
        emptyState.classList.add('flex');
    } else {
        grid.style.display = 'grid';
        emptyState.classList.add('hidden');
        emptyState.classList.remove('flex');

        function hexToRgb(hex) {
            var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
            return result ? 
                `${parseInt(result[1], 16)}, ${parseInt(result[2], 16)}, ${parseInt(result[3], 16)}` : 
                '250, 204, 21'; // default brand yellow
        }

        eventProducts.forEach(product => {
            const cat = categories.find(c => c.id === product.categoryId) || categories.find(c => c.id === event.categoryId) || categories[1];
            const catColorRgb = hexToRgb(cat.color || '#FACC15');

            const card = document.createElement('a');
            card.href = product.affiliateUrl;
            card.target = '_blank';
            card.rel = 'noopener noreferrer';
            card.className = 'product-card glass rounded-2xl overflow-hidden flex flex-col relative block';

            card.innerHTML = `
                <!-- Image Hero Section -->
                <div class="h-28 w-full relative overflow-hidden" style="background-color: rgba(${catColorRgb}, 0.15)">
                    <img src="${product.imageUrl}" alt="${L(product.name)}" class="w-full h-full object-cover">
                    
                    <!-- Gender Badge -->
                    ${product.gender ? `
                    <div class="absolute top-2 left-2 w-6 h-6 bg-black/40 backdrop-blur-sm rounded-full flex items-center justify-center border border-white/20 shadow-sm">
                        <span class="text-xs leading-none" style="margin-top: 1px">${product.gender === 'male' ? '♂️' : product.gender === 'female' ? '♀️' : '⚧️'}</span>
                    </div>
                    ` : ''}

                    ${product.isPopular ? `
                    <div class="absolute top-2 right-2 px-2 h-5 bg-gradient-to-r from-yellow-500 to-amber-600 rounded-md shadow-lg flex items-center justify-center">
                        <span class="text-[10px] font-bold text-white tracking-wider uppercase leading-none mt-[1px]">${ui('hot')}</span>
                    </div>
                    ` : ''}
                </div>

                <!-- Info Section -->
                <div class="p-3 flex flex-col flex-grow">
                    <h3 class="text-sm font-bold text-white line-clamp-2 mb-3">${L(product.name)}</h3>
                    
                    <div class="mt-auto">
                        <div class="text-sm font-black mb-2" style="color: ${cat.color || '#FACC15'}">${product.priceRange}</div>
                        <div class="w-full py-1.5 rounded-lg border flex items-center justify-center gap-1.5 transition-colors" 
                             style="background-color: rgba(${catColorRgb}, 0.18); border-color: rgba(${catColorRgb}, 0.4)">
                            <i class="${product.platform === 'Tiktok Shop' ? 'fa-brands fa-tiktok' : 'fa-solid fa-bag-shopping'} text-[11px]" style="color: ${cat.color || '#FACC15'}"></i>
                            <span class="text-xs font-bold" style="color: ${cat.color || '#FACC15'}">${product.platform || ui('viewNow')}</span>
                        </div>
                    </div>
                </div>
            `;
            grid.appendChild(card);
        });
    }
});
