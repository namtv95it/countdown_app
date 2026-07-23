const project = 'lovin-c69f3';
const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/gifts`;

const newImages = [
    "https://images.unsplash.com/photo-1599839619722-39751411ea63?q=80&w=600&auto=format&fit=crop", // Plush
    "https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=600&auto=format&fit=crop", // Lipstick
    "https://images.unsplash.com/photo-1524805444758-089113d48a6d?q=80&w=600&auto=format&fit=crop", // Watch
    "https://images.unsplash.com/photo-1563241527-3004b7be0ffd?q=80&w=600&auto=format&fit=crop", // Flowers
    "https://images.unsplash.com/photo-1606220588913-b3aacb4d2f46?q=80&w=600&auto=format&fit=crop", // Earbuds
    "https://images.unsplash.com/photo-1602874801007-bd458cb6c975?q=80&w=600&auto=format&fit=crop", // Candle
    "https://images.unsplash.com/photo-1627123424574-724758594e93?q=80&w=600&auto=format&fit=crop", // Wallet
    "https://images.unsplash.com/photo-1522204523234-8729aa6e3d5f?q=80&w=600&auto=format&fit=crop", // Tech
    "https://images.unsplash.com/photo-1549465220-1a8b9238cd48?q=80&w=600&auto=format&fit=crop", // Gift box
    "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?q=80&w=600&auto=format&fit=crop"  // Backpack
];

async function run() {
  try {
    const res = await fetch(url);
    const data = await res.json();
    if (!data.documents) {
      console.log("No documents found.");
      return;
    }
    
    let success = 0;
    for (let i = 0; i < data.documents.length; i++) {
      const doc = data.documents[i];
      const docName = doc.name;
      // Get an image
      const img = newImages[i % newImages.length];
      
      // We use the patch method to update only the imageUrl field
      const updateUrl = `https://firestore.googleapis.com/v1/${docName}?updateMask.fieldPaths=imageUrl`;
      const body = {
        fields: {
          imageUrl: { stringValue: img }
        }
      };
      
      const patchRes = await fetch(updateUrl, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body)
      });
      
      if (patchRes.ok) success++;
      else console.error("Failed to update:", await patchRes.text());
    }
    console.log(`Successfully updated ${success} images.`);
  } catch (e) {
    console.error(e);
  }
}
run();
