const fs = require('fs');
const transcriptPath = "C:\\Users\\namtv\\.gemini\\antigravity-ide\\brain\\a5849ddc-0fc8-4541-8b18-b2ad86cc7df9\\.system_generated\\logs\\transcript_full.jsonl";

let giftServiceContent = "";

const data = fs.readFileSync(transcriptPath, 'utf-8');
const lines = data.split('\n');

for (const line of lines) {
    if (!line.trim()) continue;
    try {
        const obj = JSON.parse(line);
        if (obj.type === 'PLANNER_RESPONSE' && obj.tool_calls) {
            for (const call of obj.tool_calls) {
                if (call.name === 'write_to_file') {
                    const targetFile = call.args.TargetFile || '';
                    if (targetFile.includes('gift_service.dart')) {
                        giftServiceContent = call.args.CodeContent;
                    }
                }
            }
        }
    } catch (e) {
    }
}

if (giftServiceContent) {
    fs.writeFileSync("d:\\Git\\countdown_app\\lib\\services\\gift_service.dart", giftServiceContent);
    console.log("Recovered gift_service.dart");
} else {
    console.log("gift_service.dart not found in transcript");
}
