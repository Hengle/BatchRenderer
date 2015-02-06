

void ApplyBillboardTransform(float2 id, inout float4 vertex, inout float3 normal, inout float2 texcoord, inout float4 color)
{
    int instance_id = GetBatchBegin() + id.x;
    if(instance_id >= GetNumInstances()) {
        vertex.xyz *= 0.0;
        return;
    }

    float3 camera_pos = _WorldSpaceCameraPos.xyz;
    float3 pos = GetInstanceTranslation(instance_id);
    float3 look = normalize(camera_pos-pos);
    float3 axis = cross(look, float3(0.0, 1.0, 0.0));
    float3 up = mul(axis_rotation_matrix33(axis, 90.0), look);

    vertex.xyz *= GetBaseScale();
    if(GetFlag_Scale()) {
        vertex.xyz *= GetInstanceScale(instance_id);
    }
    vertex.xyz = mul(look_matrix33(look, up), vertex.xyz);
    if(GetFlag_Rotation()) {
        float3x3 rot = quaternion_to_matrix33(GetInstanceRotation(instance_id));
        vertex.xyz = mul(rot, vertex.xyz);
        normal = mul(rot, normal);
    }
    vertex.xyz += pos;
    vertex = mul(UNITY_MATRIX_VP, vertex);

    if(GetFlag_UVOffset()) {
        float4 u = GetInstanceUVOffset(instance_id);
        texcoord = texcoord*u.xy + u.zw;
    }
    if(GetFlag_Color()) {
        color *= GetInstanceColor(instance_id);
    }
}


bool ApplyViewPlaneProjection(inout float4 vertex, float3 pos)
{
    float4 vp = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
    if(vp.z<0.0) {
        vertex.xyz *= 0.0;
        return false;
    }

    float aspect = _ScreenParams.x / _ScreenParams.y;
    float3 camera_pos = _WorldSpaceCameraPos.xyz;
    float3 look = normalize(camera_pos-pos);
    Plane view_plane = {look, 1.0};
    pos = camera_pos + project_to_plane(view_plane, pos-camera_pos);
    vertex.y *= -aspect;
    vertex.xy += vp.xy / vp.w;
    vertex.zw = float2(0.0, 1.0);
    return true;
}

void ApplyViewPlaneBillboardTransform(float2 id, inout float4 vertex, inout float3 normal, inout float2 texcoord, inout float4 color)
{
    int instance_id = GetBatchBegin() + id.x;
    if(instance_id >= GetNumInstances()) {
        vertex.xyz *= 0.0;
        return;
    }

    float3 pos = GetInstanceTranslation(instance_id);
    vertex.xyz *= GetBaseScale();
    if(GetFlag_Scale()) {
        vertex.xyz *= GetInstanceScale(instance_id);
    }
    if(GetFlag_Rotation()) {
        float3x3 rot = quaternion_to_matrix33(GetInstanceRotation(instance_id));
        vertex.xyz = mul(rot, vertex.xyz);
        normal = mul(rot, normal);
    }
    if(!ApplyViewPlaneProjection(vertex, pos)) {
        return;
    }

    if(GetFlag_UVOffset()) {
        float4 u = GetInstanceUVOffset(instance_id);
        texcoord = texcoord*u.xy + u.zw;
    }
    if(GetFlag_Color()) {
        color *= GetInstanceColor(instance_id);
    }
}



sampler2D _MainTex;

struct appdata_t {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 texcoord : TEXCOORD0;
    float2 texcoord1 : TEXCOORD1;
};

struct v2f {
    float4 vertex : SV_POSITION;
    float2 texcoord : TEXCOORD0;
    float4 color : TEXCOORD1;
};

v2f vert(appdata_t v)
{
    float4 color = 1.0;
    ApplyBillboardTransform(v.texcoord1, v.vertex, v.normal, v.texcoord, color);

    v2f o;
    o.vertex = v.vertex;
    o.texcoord = v.texcoord;
    o.color = color;
    return o;
}

v2f vert_fixed(appdata_t v)
{
    float4 color = 1.0;
    ApplyViewPlaneBillboardTransform(v.texcoord1, v.vertex, v.normal, v.texcoord, color);

    v2f o;
    o.vertex = v.vertex;
    o.texcoord = v.texcoord;
    o.color = color;
    return o;
}

float4 frag(v2f i) : SV_Target
{
    float4 color = tex2D(_MainTex, i.texcoord) * i.color;
    return color;
}
