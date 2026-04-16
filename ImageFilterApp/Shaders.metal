//
//  Shaders.metal
//  ImageFilterApp
//
//  Created by Takayuki Sakamoto on 2026/04/11.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                              constant float *vertices [[buffer(0)]]) {
    
    VertexOut out;
    
    // 1頂点 = 4要素(x, y, u, v)
    int index = vertexID * 6;
    
    float4 position = float4(
        vertices[index + 0],
        vertices[index + 1],
        vertices[index + 2],
        vertices[index + 3]
    );
    
    float2 uv = float2(
        vertices[index + 4],
        vertices[index + 5]
    );
    
    out.position = position;
    out.texCoord = uv;
    
    return out;
}

fragment float4 grayscaleFragment(VertexOut in [[stage_in]],
                                  texture2d<float> tex [[texture(0)]],
                                  constant float &intensity [[buffer(0)]],
                                  constant float &split [[buffer(1)]]) {
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    float4 color = tex.sample(s, in.texCoord);
    
    float gray = dot(color.rgb, float3(0.299, 0.587, 0.144));
    float3 grayColor = float3(gray, gray, gray);
    
    float3 result = color.rgb * (1.0 -intensity) + grayColor * intensity;
    
    // スライダー
    if (in.texCoord.x > split) {
        return color; // 元画像
    }
    if (abs(in.texCoord.x - split) < 0.002) {
        return float4(1, 1, 1, 1);  // 白線
    }
    
    return float4(result, color.a);
    
}

fragment float4 sepiaFragment(VertexOut in [[stage_in]],
                              texture2d<float> tex [[texture(0)]],
                              constant float &intensity [[buffer(0)]],
                              constant float &split [[buffer(1)]]) {
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    float4 color = tex.sample(s, in.texCoord);
    
    float3 sepia = float3(
    dot(color.rgb, float3(0.393, 0.769, 0.189)),
    dot(color.rgb, float3(0.349, 0.686, 0.168)),
    dot(color.rgb, float3(0.272, 0.534, 0.131))
    );

    float3 result = color.rgb * (1.0 - intensity) + sepia * intensity;
    
    if (in.texCoord.x > split) {
        return color; // 元画像
    }
    if (abs(in.texCoord.x - split) < 0.002) {
        return float4(1, 1, 1, 1);
    }
    
    return float4(result, color.a);
}

fragment float4 blurFragment(VertexOut in [[stage_in]],
                             texture2d<float> tex [[texture(0)]],
                             constant float &intensity [[buffer(0)]],
                             constant float &split [[buffer(1)]]) {
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    float2 uv = in.texCoord;
    float2 offset = float2(0.01 * intensity, 0.01 * intensity);
    
    float4 color = tex.sample(s, uv) * 0.2;
    color += tex.sample(s, uv + float2(offset.x, 0)) * 0.2;
    color += tex.sample(s, uv - float2(offset.x, 0)) * 0.2;
    color += tex.sample(s, uv + float2(0, offset.y)) * 0.2;
    color += tex.sample(s, uv - float2(0, offset.y)) * 0.2;
    
    // 白線
    if (abs(uv.x - split) < 0.002) {
        return float4(1, 1, 1, 1);
    }
    
    // Before / After
    if (uv.x > split) {
        return tex.sample(s, uv);
    }
    
    return color;
}

/*
 fragment float4 blurHorizontal(VertexOut in [[stage_in]],
                                texture2d<float> tex [[texture(0)]],
                                constant float &intensity [[buffer(0)]],
                                constant float &split [[buffer(1)]]) {
     
     constexpr sampler s(address::clamp_to_edge, filter::linear);
     
     float2 texSize = float2(tex.get_width(), tex.get_height());
     float2 uv = in.texCoord;
     
     float radius = intensity * 10.0;
     
     float3 color = float3(0.0);
     float total = 0.0;
     
     for (int i = -10; i <= 10; i++) {
         float weight = exp(-float(i*i) / 30.0);
         float2 offset = float2(i, 0) / texSize * radius;
         
         color += tex.sample(s, uv + offset).rgb * weight;
         total += weight;
     }
     
     return float4(color / total, 1.0);
 }
 
 
fragment float4 blurVertical(VertexOut in [[stage_in]],
                             texture2d<float> tex [[texture(0)]],
                             constant float &intensity [[buffer(0)]],
                             constant float &split [[buffer(1)]]) {
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    float2 texSize = float2(tex.get_width(), tex.get_height());
    float2 uv = in.texCoord;
    
    if (abs(uv.x - split) < 0.005) {
        return float4(1, 1, 1, 1); // 白線
    }
    
    // Before（左）
    if (uv.x < split) {
        return tex.sample(s, uv);
    }
    
    // After（右）
    float adjusted = intensity * intensity;
    float radius = 2.0 + adjusted * 8.0;
    
    float3 color = float3(0.0);
    float total = 0.0;
    
    for (int i = -10; i <=10; i++) {
        float weight = exp(-float(i*i) / 30.0);
        float2 offset = float2(0, i) / texSize * radius;
        
        color += tex.sample(s, uv + offset).rgb * weight;
        total += weight;
    }
    
    return float4(color / total, 1.0);
}
*/
 
fragment float4 normalFragment(VertexOut in [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &intensity [[buffer(0)]],
                               constant float &split [[buffer(1)]]) {
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    float4 color = tex.sample(s, in.texCoord);
    
    return color;
}

