//���ʃ��J�V�F�[�_
//�r�[���}��P

#define USE_BEVEL


//�t���e�N�X�`���t���O
//�@//#define�`�@�ƁA//������ƗL����
//�e�N�X�`���������K�v�ł��B�ڂ����͓����́u�t���e�N�X�`���ɂ���.txt�v���Q�Ƃ̎�
//#define USE_FULLMODE

//���ʌW��
float Mirror_Param = 0.5;

//�t�B�����C�g�F
float3 FillLight = float3(104,104,124)/255.0;
//�o�b�N���C�g�F
float3 BackLight = float3(82,92,100)/255.0;
//��F
float3 SkyColor = float3(0.9f, 0.9f, 1.0f);
//�n�ʐF
float3 GroundColor = float3(0.1f, 0.05f, 0.0f);
//�e��}�b�v���x
float MapParam = 1;
//���Ȕ��F�}���l
float EmmisiveParam = 1;
//�x�x���̍L��
float BevelParam = 1;
//�x�x������
float BevelPow = 1.0;

//�X�y�L�����{��
float SpecularPow = 2;
//�n�[�t�����o�[�g�W�� 0�Ń����o�[�g���� 1�Ńn�[�t�����o�[�g����
float HalfLambParam = 0;



float X_SHADOWPOWER = 1.0;   //�A�N�Z�T���e�Z��
float PMD_SHADOWPOWER = 0.2; //���f���e�Z��


//�X�N���[���V���h�E�}�b�v�擾
shared texture2D ScreenShadowMapProcessed : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    string Format = "D3DFMT_R16F";
>;
sampler2D ScreenShadowMapProcessedSamp = sampler_state {
    texture = <ScreenShadowMapProcessed>;
    MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = NONE;
    AddressU  = CLAMP; AddressV = CLAMP;
};

//SSAO�}�b�v�擾
shared texture2D ExShadowSSAOMapOut : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    string Format = "R16F";
>;

sampler2D ExShadowSSAOMapSamp = sampler_state {
    texture = <ExShadowSSAOMapOut>;
    MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = NONE;
    AddressU  = CLAMP; AddressV = CLAMP;
};

// �X�N���[���T�C�Y
float2 ES_ViewportSize : VIEWPORTPIXELSIZE;
static float2 ES_ViewportOffset = (float2(0.5,0.5)/ES_ViewportSize);

bool Exist_ExcellentShadow : CONTROLOBJECT < string name = "ExcellentShadow.x"; >;
bool Exist_ExShadowSSAO : CONTROLOBJECT < string name = "ExShadowSSAO.x"; >;
float ShadowRate : CONTROLOBJECT < string name = "ExcellentShadow.x"; string item = "Tr"; >;
float3   ES_CameraPos1      : POSITION  < string Object = "Camera"; >;
float es_size0 : CONTROLOBJECT < string name = "ExcellentShadow.x"; string item = "Si"; >;
float4x4 es_mat1 : CONTROLOBJECT < string name = "ExcellentShadow.x"; >;

static float3 es_move1 = float3(es_mat1._41, es_mat1._42, es_mat1._43 );
static float CameraDistance1 = length(ES_CameraPos1 - es_move1); //�J�����ƃV���h�E���S�̋���



///////////////////////////////////////////////////////////////////
// ���I�o�����ʊ��}�b�v�̐錾���g�p�֐�

#define WIDTH       128
#define HEIGHT      128
#define ANTI_ALIAS  true


texture EnvMapF: OFFSCREENRENDERTARGET <
    int Width = WIDTH;
    int Height = HEIGHT;
    float4 ClearColor = { 1, 1, 1, 1 };
    float ClearDepth = 1.0;
    bool AntiAlias = ANTI_ALIAS;
    int Miplevels=1;
    string DefaultEffect = 
        "self = hide;"
        "*=DPEnvMapF.fx;";
>;

sampler sampEnvMapF = sampler_state {
    texture = <EnvMapF>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

texture EnvMapB: OFFSCREENRENDERTARGET <
    int Width = WIDTH;
    int Height = HEIGHT;
    float4 ClearColor = { 1, 1, 1, 1 };
    float ClearDepth = 1.0;
    bool AntiAlias = ANTI_ALIAS;
    int Miplevels=1;
    string DefaultEffect = 
        "self = hide;"
        "*=DPEnvMapB.fx;";
>;

sampler sampEnvMapB = sampler_state {
    texture = <EnvMapB>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

float4 texDP(sampler2D sampFront, sampler2D sampBack, float3 vec) {
    vec = normalize(vec);
    bool front = (vec.z >= 0);
    if ( !front ) vec.xz = -vec.xz;
    
    float2 uv;
    uv = vec.xy / (1+vec.z);
    uv.y = -uv.y;
    uv = uv * 0.5 + 0.5;
    
    if ( front ) {
        return tex2D(sampFront, uv);
    } else {
        return tex2D(sampBack, uv);
    }
}



// �X�N���[���T�C�Y
float2 ViewportSize : VIEWPORTPIXELSIZE;
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);
static float2 SampStep = (BevelParam/ViewportSize);

////////////////////////////////////////////////////////////////////////////////////////////////
//
//  �x�[�X
//  full.fx ver1.3
//  �쐬: ���͉��P
//
////////////////////////////////////////////////////////////////////////////////////////////////
// �p�����[�^�錾

// ���@�ϊ��s��
float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 WorldMatrix              : WORLD;
float4x4 ViewMatrix               : VIEW;
float4x4 LightWorldViewProjMatrix : WORLDVIEWPROJECTION < string Object = "Light"; >;

float3   LightDirection    : DIRECTION < string Object = "Light"; >;
float3   CameraPosition    : POSITION  < string Object = "Camera"; >;

// �}�e���A���F
float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;
float3   MaterialAmbient   : AMBIENT  < string Object = "Geometry"; >;
float3   MaterialEmmisive  : EMISSIVE < string Object = "Geometry"; >;
float3   MaterialSpecular  : SPECULAR < string Object = "Geometry"; >;
float    SpecularPower     : SPECULARPOWER < string Object = "Geometry"; >;
float3   MaterialToon      : TOONCOLOR;
float4   EdgeColor         : EDGECOLOR;
// ���C�g�F
float3   LightDiffuse      : DIFFUSE   < string Object = "Light"; >;
float3   LightAmbient      : AMBIENT   < string Object = "Light"; >;
float3   LightSpecular     : SPECULAR  < string Object = "Light"; >;
static float4 DiffuseColor  = MaterialDiffuse  * float4(LightDiffuse, 1.0f);
static float3 AmbientColor  = saturate(MaterialAmbient * LightAmbient);
static float3 SpecularColor = MaterialSpecular * LightSpecular;

bool     parthf;   // �p�[�X�y�N�e�B�u�t���O
bool     transp;   // �������t���O
bool	 spadd;    // �X�t�B�A�}�b�v���Z�����t���O
#define SKII1    1500
#define SKII2    8000
#define Toon     3
// �����_�����O�^�[�Q�b�g�̃N���A�l
float4 ClearColor = {0,0,0,0};
float ClearDepth  = 1.0;

//���Ȃ̖@����ۑ�����e�N�X�`��
texture NormalTex : RenderColorTarget
<
    float2 ViewPortRatio = {1.0,1.0};
    string Format = "D3DFMT_A16B16G16R16F" ;
>;
sampler NormalSampler = sampler_state {
    texture = <NormalTex>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};
texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    string Format = "D24S8";
>;


// �I�u�W�F�N�g�̃e�N�X�`��
texture ObjectTexture: MATERIALTEXTURE;
#define ANISO_NUM 16
sampler ObjTexSampler = sampler_state {
    texture = <ObjectTexture>;
	MINFILTER = ANISOTROPIC;
	MAGFILTER = ANISOTROPIC;
	MIPFILTER = ANISOTROPIC;
	
	MAXANISOTROPY = ANISO_NUM;
};
// �X�t�B�A�}�b�v�̃e�N�X�`��
texture ObjectSphereMap: MATERIALSPHEREMAP;
sampler ObjSphareSampler = sampler_state {
    texture = <ObjectSphereMap>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

texture2D SpMap <
    string ResourceName = "SpMap.png";
>;
sampler SpMapSamp = sampler_state {
    texture = <SpMap>;
	MINFILTER = ANISOTROPIC;
	MAGFILTER = ANISOTROPIC;
	MIPFILTER = ANISOTROPIC;
	
	MAXANISOTROPY = ANISO_NUM;
};
texture2D HeightMap <
    string ResourceName = "HeightMap.png";
>;
sampler HeightMapSamp = sampler_state {
    texture = <HeightMap>;
	MINFILTER = ANISOTROPIC;
	MAGFILTER = ANISOTROPIC;
	MIPFILTER = ANISOTROPIC;
	
	MAXANISOTROPY = ANISO_NUM;
};
texture2D NormalMap <
    string ResourceName = "NormalMap.png";
>;
sampler NormalMapSamp = sampler_state {
    texture = <NormalMap>;
	MINFILTER = ANISOTROPIC;
	MAGFILTER = ANISOTROPIC;
	MIPFILTER = ANISOTROPIC;
	
	MAXANISOTROPY = ANISO_NUM;
};

// MMD�{����sampler���㏑�����Ȃ����߂̋L�q�ł��B�폜�s�B
sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);

////////////////////////////////////////////////////////////////////////////////////////////////
// �֊s�`��

// ���_�V�F�[�_
float4 ColorRender_VS(float4 Pos : POSITION) : POSITION 
{
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    return mul( Pos, WorldViewProjMatrix );
}

// �s�N�Z���V�F�[�_
float4 ColorRender_PS() : COLOR
{
    // �֊s�F�œh��Ԃ�
    return EdgeColor;
}

// �֊s�`��p�e�N�j�b�N
technique EdgeTec < string MMDPass = "edge"; > {
    pass DrawEdge {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable  = FALSE;

        VertexShader = compile vs_3_0 ColorRender_VS();
        PixelShader  = compile ps_3_0 ColorRender_PS();
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// �e�i��Z���t�V���h�E�j�`��

// ���_�V�F�[�_
float4 Shadow_VS(float4 Pos : POSITION) : POSITION
{
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    return mul( Pos, WorldViewProjMatrix );
}

// �s�N�Z���V�F�[�_
float4 Shadow_PS() : COLOR
{
    // �A���r�G���g�F�œh��Ԃ�
    return float4(AmbientColor.rgb, 0.65f);
}

// �e�`��p�e�N�j�b�N
technique ShadowTec < string MMDPass = "shadow"; > {
    pass DrawShadow {
        VertexShader = compile vs_3_0 Shadow_VS();
        PixelShader  = compile ps_3_0 Shadow_PS();
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// �I�u�W�F�N�g�`��i�Z���t�V���h�EOFF�j

struct VS_OUTPUT {
    float4 Pos        : POSITION;    // �ˉe�ϊ����W
    float2 Tex        : TEXCOORD1;   // �e�N�X�`��
    float3 Normal     : TEXCOORD2;   // �@��
    float3 Eye        : TEXCOORD3;   // �J�����Ƃ̑��Έʒu
    float2 SpTex      : TEXCOORD4;	 // �X�t�B�A�}�b�v�e�N�X�`�����W
    float4 WorldPos      : TEXCOORD5;     // ���[���h��ԍ��W
    float4 Color      : COLOR0;      // �f�B�t���[�Y�F
};

// ���_�V�F�[�_
VS_OUTPUT Basic_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;
    Out.WorldPos = Pos;
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    Out.Pos = mul( Pos, WorldViewProjMatrix );
    
    // �J�����Ƃ̑��Έʒu
    Out.Eye = CameraPosition - mul( Pos, WorldMatrix );
    // ���_�@��
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );
    
    // �f�B�t���[�Y�F�{�A���r�G���g�F �v�Z
    Out.Color.rgb = AmbientColor;
    if ( !useToon ) {
        Out.Color.rgb += max(0,dot( Out.Normal, -LightDirection )) * DiffuseColor.rgb;
    }
    Out.Color.a = DiffuseColor.a;
    Out.Color = saturate( Out.Color );
    
    // �e�N�X�`�����W
    Out.Tex = Tex;
    
    if ( useSphereMap ) {
        // �X�t�B�A�}�b�v�e�N�X�`�����W
        float2 NormalWV = mul( Out.Normal, (float3x3)ViewMatrix );
        Out.SpTex.x = NormalWV.x * 0.5f + 0.5f;
        Out.SpTex.y = NormalWV.y * -0.5f + 0.5f;
    }
    
    return Out;
}

// �s�N�Z���V�F�[�_
float4 Basic_PS(VS_OUTPUT IN, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon) : COLOR0
{
	return IN.Color;
}
technique MainTec1 < string MMDPass = "object"; bool UseTexture = true; bool UseSphereMap = false; bool UseToon = false; > {
    pass DrawObject {
        VertexShader = compile vs_2_0 Basic_VS(true, false, false);
        PixelShader  = compile ps_2_0 Basic_PS(true, false, false);
    }
}

technique MainTec2 < string MMDPass = "object"; bool UseTexture = false; bool UseSphereMap = true; bool UseToon = false; > {
    pass DrawObject {
        VertexShader = compile vs_2_0 Basic_VS(false, true, false);
        PixelShader  = compile ps_2_0 Basic_PS(false, true, false);
    }
}

technique MainTec3 < string MMDPass = "object"; bool UseTexture = true; bool UseSphereMap = true; bool UseToon = false; > {
    pass DrawObject {
        VertexShader = compile vs_2_0 Basic_VS(true, true, false);
        PixelShader  = compile ps_2_0 Basic_PS(true, true, false);
    }
}

// �I�u�W�F�N�g�`��p�e�N�j�b�N�iPMD���f���p�j
technique MainTec4 < string MMDPass = "object"; bool UseTexture = false; bool UseSphereMap = false; bool UseToon = true; > {
    pass DrawObject {
        VertexShader = compile vs_2_0 Basic_VS(false, false, true);
        PixelShader  = compile ps_2_0 Basic_PS(false, false, true);
    }
}

technique MainTec5 < string MMDPass = "object"; bool UseTexture = true; bool UseSphereMap = false; bool UseToon = true; > {
    pass DrawObject {
        VertexShader = compile vs_2_0 Basic_VS(true, false, true);
        PixelShader  = compile ps_2_0 Basic_PS(true, false, true);
    }
}

technique MainTec6 < string MMDPass = "object"; bool UseTexture = false; bool UseSphereMap = true; bool UseToon = true; > {
    pass DrawObject {
        VertexShader = compile vs_2_0 Basic_VS(false, true, true);
        PixelShader  = compile ps_2_0 Basic_PS(false, true, true);
    }
}

technique MainTec7 < string MMDPass = "object"; bool UseTexture = true; bool UseSphereMap = true; bool UseToon = true; > {
    pass DrawObject {
        VertexShader = compile vs_2_0 Basic_VS(true, true, true);
        PixelShader  = compile ps_2_0 Basic_PS(true, true, true);
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////
// �Z���t�V���h�E�pZ�l�v���b�g

struct VS_ZValuePlot_OUTPUT {
    float4 Pos : POSITION;              // �ˉe�ϊ����W
    float4 ShadowMapTex : TEXCOORD0;    // Z�o�b�t�@�e�N�X�`��
};

// ���_�V�F�[�_
VS_ZValuePlot_OUTPUT ZValuePlot_VS( float4 Pos : POSITION,float2 Tex : TEXCOORD0 )
{
    VS_ZValuePlot_OUTPUT Out = (VS_ZValuePlot_OUTPUT)0;

    // ���C�g�̖ڐ��ɂ�郏�[���h�r���[�ˉe�ϊ�������
    Out.Pos = mul( Pos, LightWorldViewProjMatrix );

    // �e�N�X�`�����W�𒸓_�ɍ��킹��
    Out.ShadowMapTex = Out.Pos;

    return Out;
}

// �s�N�Z���V�F�[�_
float4 ZValuePlot_PS( float4 ShadowMapTex : TEXCOORD0 ) : COLOR
{
    // R�F������Z�l���L�^����
    return float4(ShadowMapTex.z/ShadowMapTex.w,0,0,1);
}

// Z�l�v���b�g�p�e�N�j�b�N
technique ZplotTec < string MMDPass = "zplot"; > {
    pass ZValuePlot {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 ZValuePlot_VS();
        PixelShader  = compile ps_3_0 ZValuePlot_PS();
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// �I�u�W�F�N�g�`��i�Z���t�V���h�EON�j


// �V���h�E�o�b�t�@�̃T���v���B"register(s0)"�Ȃ̂�MMD��s0���g���Ă��邩��
sampler DefSampler : register(s0);

struct BufferShadow_OUTPUT {
    float4 Pos      : POSITION;     // �ˉe�ϊ����W
    float4 ZCalcTex : TEXCOORD0;    // Z�l
    float2 Tex      : TEXCOORD1;    // �e�N�X�`��
    float3 Normal   : TEXCOORD2;    // �@��
    float3 Eye      : TEXCOORD3;    // �J�����Ƃ̑��Έʒu
    float2 SpTex    : TEXCOORD4;	 // �X�t�B�A�}�b�v�e�N�X�`�����W
    float4 WorldPos      : TEXCOORD5;     // ���[���h��ԍ��W
    float4 Color    : COLOR0;       // �f�B�t���[�Y�F
    float4 LocalPos		: TEXCOORD6;
    float4 LastPos	: TEXCOORD7;
    float4 ScreenTex : TEXCOORD8;   // �X�N���[�����W
};

// ���_�V�F�[�_
BufferShadow_OUTPUT BufferShadow_Mec_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon)
{
    BufferShadow_OUTPUT Out = (BufferShadow_OUTPUT)0;
	Out.LocalPos = Pos;
	Out.WorldPos = mul( Pos, WorldMatrix );
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    Out.Pos = mul( Pos, WorldViewProjMatrix );
    
    // �J�����Ƃ̑��Έʒu
    Out.Eye = CameraPosition - mul( Pos, WorldMatrix );
    // ���_�@��
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );
	// ���C�g���_�ɂ�郏�[���h�r���[�ˉe�ϊ�
    Out.ZCalcTex = mul( Pos, LightWorldViewProjMatrix );
    
    // �f�B�t���[�Y�F�{�A���r�G���g�F �v�Z
    Out.Color.rgb = AmbientColor;
    if ( !useToon ) {
        Out.Color.rgb += max(0,dot( Out.Normal, -LightDirection )) * DiffuseColor.rgb;
    }
    Out.Color.a = DiffuseColor.a;
    Out.Color = saturate( Out.Color );
    
    // �e�N�X�`�����W
    Out.Tex = Tex;
    Out.LastPos = Out.Pos;
    
    if ( useSphereMap ) {
        // �X�t�B�A�}�b�v�e�N�X�`�����W
        float2 NormalWV = mul( Out.Normal, (float3x3)ViewMatrix );
        Out.SpTex.x = NormalWV.x * 0.5f + 0.5f;
        Out.SpTex.y = NormalWV.y * -0.5f + 0.5f;
    }

    //�X�N���[�����W�擾
    Out.ScreenTex = Out.Pos;
    
    //�����i�ɂ����邿����h�~
    Out.Pos.z -= max(0, (int)((CameraDistance1 - 6000) * 0.04));
    
    return Out;
}
float3x3 compute_tangent_frame(float3 Normal, float3 View, float2 UV)
{
  float3 dp1 = ddx(View);
  float3 dp2 = ddy(View);
  float2 duv1 = ddx(UV);
  float2 duv2 = ddy(UV);

  float3x3 M = float3x3(dp1, dp2, cross(dp1, dp2));
  float2x3 inverseM = float2x3(cross(M[1], M[2]), cross(M[2], M[0]));
  float3 Tangent = mul(float2(duv1.x, duv2.x), inverseM);
  float3 Binormal = mul(float2(duv1.y, duv2.y), inverseM);

  return float3x3(normalize(Tangent), normalize(Binormal), Normal);
}

float4 CalcNormal(float2 Tex,float3 Eye,float3 Normal, bool useTexture)
{
	float4 Norm = 1;
	
	#ifdef USE_FULLMODE
		float2 full_tex = abs(frac(Tex)*0.5);
	#endif
    float2 tex = Tex* MapParam;
	float4 Color;
	float3 normal;
	float height = 0;
	
	height = tex2D( HeightMapSamp, Tex * MapParam).r;
	float4 NormalColor = tex2D( NormalMapSamp, tex)*2;	
	
	#ifdef USE_FULLMODE
	if ( useTexture ) {
		height = tex2D( ObjTexSampler, full_tex+float2(0.5,0.5)).r;
		NormalColor *= tex2D( ObjTexSampler, full_tex+float2(0,0.5))*2;
	}
	#endif
	
	NormalColor = NormalColor.rgba;
	NormalColor.a = 1;
	float3x3 tangentFrame = compute_tangent_frame(Normal, Eye, Tex);
	Norm.rgb = normalize(mul(NormalColor - 1.0f, tangentFrame));

	return Norm;
}

// �@���o�̓V�F�[�_
float4 Normal_PS(VS_OUTPUT IN,uniform bool useTexture) : COLOR0
{
	return CalcNormal(IN.Tex,normalize(IN.Eye),normalize(IN.Normal),useTexture);
}


//�׃b�N�}�����z�v�Z�֐�
inline float CalcBeckman(float m, float cosbeta)
{
	return (
		exp(-(1-(cosbeta*cosbeta))/(m*m*cosbeta*cosbeta))
		/(4*m*m*cosbeta*cosbeta*cosbeta*cosbeta)
		);
}

//�t���l���v�Z�֐�
inline float CalcFresnel(float n, float c)
{
	float g = sqrt(n*n + c*c - 1);
	float T1 = ((g-c)*(g-c))/((g+c)*(g+c));
	float T2 = 1 + ( (c*(g+c)-1)*(c*(g+c)-1) )/( (c*(g-c)+1)*(c*(g-c)+1) );
	return 0.5 * T1 * T2;
}

//�X�y�L�����v�Z�֐�
inline float3 CalcSpecular(float3 L,float3 N,float3 V,float3 Col)
{
	float3 H = normalize(L + V);	//�n�[�t�x�N�g��

	//float3 Specular = pow( max(0,dot( H, normalize(N) )), (SpecularPower+AddSpecularPow)) * (Col);
    //return Specular;

	//�v�Z�Ɏg���p�x
	float NV = dot(N, V);
	float NH = dot(N, H);
	float VH = dot(V, H);
	float NL = dot(N, L);

	//Beckmann���z�֐�
	float D = CalcBeckman(0.35f, NH);

	//�􉽌�����
	float G = min(1, min(2*NH*NV/VH, 2*NH*NL/VH));

	//�t���l����
	float F = CalcFresnel(20.0f, dot(L, H));
	
	return max(0, F*D*G/NV)*1 * Col;
}

float2 test[]=
{
	{1,0},	{0,1},
	{-1,0},	{0,-1},
	{1,-1},	{-1,1},
	{1,1},	{-1,-1},
};


// �s�N�Z���V�F�[�_
float4 BufferShadow_Mec_PS(BufferShadow_OUTPUT IN, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon) : COLOR
{
    #ifdef USE_FULLMODE
		float2 full_tex = abs(frac(IN.Tex)*0.5);
	#endif
	
	float2 ScrTex;
    ScrTex.x = (IN.LastPos.x / IN.LastPos.w)*0.5+0.5;
	ScrTex.y = (-IN.LastPos.y / IN.LastPos.w)*0.5+0.5;
	
	IN.Normal = CalcNormal(IN.Tex,normalize(IN.Eye),normalize(IN.Normal),useTexture).rgb;
	IN.Normal = normalize(IN.Normal);
	
	#ifdef USE_BEVEL
		float3 BaseNormal = IN.Normal;
		IN.Normal = (tex2D(NormalSampler,ScrTex).rgb);
		
		//9�_�T���v�����O
		for(int i=0;i<8;i++)
		{
			IN.Normal += tex2D(NormalSampler,ScrTex+test[i]*SampStep).rgb;
		}
		IN.Normal = lerp(BaseNormal,normalize(IN.Normal),BevelPow);
	#endif
	
    float3 normal = IN.Normal;
	float3 Eye = normalize(IN.Eye);
	float height = tex2D( HeightMapSamp, IN.Tex * MapParam).r;
	float2 tex = IN.Tex * MapParam - Eye.xy * height*0.005;
    
    //return float4(normal,1);
    
    float4 Color = 1;
    Color.a = IN.Color.a;

	float half_mul = lerp(1,0.5,HalfLambParam);
	float half_add = lerp(0,0.5,HalfLambParam);
	Color.rgb = max(0,dot( normal, -LightDirection )*half_mul+half_add) * AmbientColor * LightAmbient * 2;
	Color.rgb += max(0,dot( normal, normalize(normalize(-Eye) ) )*half_mul+half_add) * AmbientColor * BackLight*2* LightAmbient * 2;
	Color.rgb += max(0,dot( normal, normalize(Eye) )*half_mul+half_add) * AmbientColor * FillLight*0.25* LightAmbient * 2;
	
	float3 N = normal;	//�@��
	float3 V = normalize(IN.Eye);	//�����x�N�g��
    float amount = (dot( normal, float3(0,1,0) )+1) * 0.5;
    float3 HalfSphereL = lerp( GroundColor, SkyColor, amount );
    Color.rgb += HalfSphereL*0.1;
    
    Color.rgb += (1-saturate(max(0,dot( normal, normalize(Eye)*2 ) )))*BackLight * LightAmbient;
	//return Color;
	// �X�y�L�����F�v�Z
    float3 Specular = 
    				CalcSpecular(normalize(-LightDirection),N,V,AmbientColor)  * LightAmbient
    +				CalcSpecular(normalize(-LightDirection+mul(WorldMatrix,float3(0.5,1,-0.5))),N,V,FillLight*0.5) * LightAmbient
    +				CalcSpecular(normalize(mul(WorldMatrix,float3(-0.5,0.5,10))),N,V,BackLight*0.1) * LightAmbient
    ;
    				 
    float anti_sp = tex2D( SpMapSamp, tex).r;
    #ifdef USE_FULLMODE
    	anti_sp *= tex2D( ObjTexSampler, full_tex+float2(0.5,0.0)).r;
    #endif
    Specular *= anti_sp*SpecularPow;
    //Specular = pow(Specular*1.5,8);
    //�e�X�g�o��
    //return float4(Specular,1);

    float4 ShadowColor = Color*0.8;//float4(Color, Color.a);  // �e�̐F
    //float4 ShadowColor = float4(float3(0,0,0), Color.a);  // �e��
    ShadowColor.a = Color.a;
    Color.rgb = saturate(Color.rgb+MaterialEmmisive*EmmisiveParam);
    ShadowColor.rgb = saturate(ShadowColor.rgb+MaterialEmmisive*EmmisiveParam);
	
    Color.rgb += Specular;
    if ( useTexture ) {
    	//�e�N�X�`���K�p
		#ifdef USE_FULLMODE
        	float4 TexColor = tex2D( ObjTexSampler, full_tex );
		#else
	        float4 TexColor = tex2D( ObjTexSampler, IN.Tex );	
	    #endif
		float3 reflVec = reflect(-normalize(IN.Eye), normalize(IN.Normal));
	    TexColor *= lerp(1,texDP(sampEnvMapF, sampEnvMapB, reflVec.xyz),Mirror_Param);
        Color *= TexColor;
        ShadowColor *= TexColor;
    }else{
    	float4 TexColor = 1;
		float3 reflVec = reflect(-normalize(IN.Eye), normalize(IN.Normal));
	    TexColor *= lerp(1,texDP(sampEnvMapF, sampEnvMapB, reflVec.xyz),Mirror_Param);
        Color *= TexColor;
        ShadowColor *= TexColor;
    }
    if ( useSphereMap ) {
        // �X�t�B�A�}�b�v�K�p
        float4 TexColor = tex2D(ObjSphareSampler,IN.SpTex);
        if(spadd) {
            Color.rgb += TexColor;
            ShadowColor.rgb += TexColor;
        } else {
            Color.rgb *= TexColor;
            ShadowColor.rgb *= TexColor;
        }
    }
    // �X�y�L�����K�p
    ShadowColor.rgb += Specular*0.5;
    ShadowColor.rgb = Color.rgb*0.5;
    
        
    //�����}�b�v�ɂ��F�␳
    Color.rgb *= saturate(height+0.5);
    ShadowColor.rgb *= saturate(height+0.5);
		 
    float4 WP = IN.LocalPos;
    WP.xyz += normal*height*0;
    
    //Z�e�N�X�`����蒼��
    IN.ZCalcTex = mul( WP, LightWorldViewProjMatrix );
    
    // �e�N�X�`�����W�ɕϊ�
    IN.ZCalcTex /= IN.ZCalcTex.w;
    float2 TransTexCoord;
    TransTexCoord.x = (1.0f + IN.ZCalcTex.x)*0.5f;
    TransTexCoord.y = (1.0f - IN.ZCalcTex.y)*0.5f;
    

    //Color = lerp(1,texDP(sampEnvMapF, sampEnvMapB, reflVec.xyz),0.25)*Color;

	if(Exist_ExcellentShadow){
        IN.ScreenTex.xyz /= IN.ScreenTex.w;
        float2 TransScreenTex;
        TransScreenTex.x = (1.0f + IN.ScreenTex.x) * 0.5f;
        TransScreenTex.y = (1.0f - IN.ScreenTex.y) * 0.5f;
        TransScreenTex += ES_ViewportOffset;
        float SadowMapVal = tex2D(ScreenShadowMapProcessedSamp, TransScreenTex).r;
        
        float SSAOMapVal = 0;
        
        if(Exist_ExShadowSSAO){
            SSAOMapVal = tex2D(ExShadowSSAOMapSamp , TransScreenTex).r; //�A�x�擾
        }
        
        #ifdef MIKUMIKUMOVING
            float3 lightdir = LightDirection[0];
            bool toonflag = useToon && usetoontexturemap;
        #else
            float3 lightdir = LightDirection;
            bool toonflag = useToon;
        #endif
        
        if (toonflag) {
            // �g�D�[���K�p
            SadowMapVal = min(saturate(dot(IN.Normal, -lightdir) * 3), SadowMapVal);
            ShadowColor.rgb *= MaterialToon;
            
            ShadowColor.rgb *= (1 - (1 - ShadowRate) * PMD_SHADOWPOWER);
        }else{
            ShadowColor.rgb *= (1 - (1 - ShadowRate) * X_SHADOWPOWER);
        }
        
        //�e������SSAO����
        float4 ShadowColor2 = ShadowColor;
        ShadowColor2.rgb -= ((Color.rgb - ShadowColor2.rgb) + 0.3) * SSAOMapVal * 0.2;
        ShadowColor2.rgb = max(ShadowColor2.rgb, 0);//ShadowColor.rgb * 0.5);
        
        //����������SSAO����
        Color = lerp(Color, ShadowColor, saturate(SSAOMapVal * 0.4));
        
        //�ŏI����
        Color = lerp(ShadowColor2, Color, SadowMapVal);
        
        return Color;
    }else
    if( any( saturate(TransTexCoord) != TransTexCoord ) ) {
        // �V���h�E�o�b�t�@�O
        return Color;
    } else {
    	float zcol = tex2D(DefSampler,TransTexCoord).r;
        float comp = 0;
        if(parthf) {
            // �Z���t�V���h�E mode2
            float Skill = SKII2*TransTexCoord.y;
            comp=1-saturate(max(IN.ZCalcTex.z-zcol , 0.0f)*Skill-0.3f);
        } else {
            // �Z���t�V���h�E mode1
            float Skill = SKII1-0.3f;
            comp=1-saturate(max(IN.ZCalcTex.z-zcol , 0.0f)*Skill-0.3f);
        }
        if ( useToon ) {
            // �g�D�[���K�p
            comp = min(saturate(dot(normal,-LightDirection)*Toon),comp);
            ShadowColor.rgb *= MaterialToon;
        }
       
        
        float4 ans = lerp(ShadowColor, Color, comp);
        if( transp ) ans.a = 0.5f;
        return ans;
    }
}

// �I�u�W�F�N�g�`��p�e�N�j�b�N�i�A�N�Z�T���p�j
technique MainTecBS0  < string MMDPass = "object_ss";bool UseTexture = false; bool UseSphereMap = false; bool UseToon = false; 
    string Script = 
    	#ifdef USE_BEVEL
	        "RenderColorTarget0=NormalTex;"
		    "RenderDepthStencilTarget=DepthBuffer;"
			"ClearSetColor=ClearColor;"
			"ClearSetDepth=ClearDepth;"
			"Clear=Color;"
			"Clear=Depth;"
	        "Pass=DrawNormal;"
		#endif
	    //�ŏI����
        "RenderColorTarget0=;"
	    "RenderDepthStencilTarget=;"
	    "Pass=DrawObject;"
    ;
> {
    pass DrawNormal {
        VertexShader = compile vs_3_0 Basic_VS(false, false, false);
        PixelShader  = compile ps_3_0 Normal_PS(false);
    }
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_Mec_VS(false, false, false);
        PixelShader  = compile ps_3_0 BufferShadow_Mec_PS(false, false, false);
    }
}
technique MainTecBS1  < string MMDPass = "object_ss"; bool UseTexture = true; bool UseSphereMap = false; bool UseToon = false; 
    string Script = 
    	#ifdef USE_BEVEL
	        "RenderColorTarget0=NormalTex;"
		    "RenderDepthStencilTarget=DepthBuffer;"
			"ClearSetColor=ClearColor;"
			"ClearSetDepth=ClearDepth;"
			"Clear=Color;"
			"Clear=Depth;"
	        "Pass=DrawNormal;"
		#endif

	    //�ŏI����
        "RenderColorTarget0=;"
	    "RenderDepthStencilTarget=;"
	    "Pass=DrawObject;"
    ;
> {
    pass DrawNormal {
        VertexShader = compile vs_3_0 Basic_VS(false, false, false);
        PixelShader  = compile ps_3_0 Normal_PS(true);
    }
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_Mec_VS(true, false, false);
        PixelShader  = compile ps_3_0 BufferShadow_Mec_PS(true, false, false);
    }
}

technique MainTecBS2  < string MMDPass = "object_ss"; bool UseTexture = false; bool UseSphereMap = true; bool UseToon = false; 
    string Script = 
    	#ifdef USE_BEVEL
	        "RenderColorTarget0=NormalTex;"
		    "RenderDepthStencilTarget=DepthBuffer;"
			"ClearSetColor=ClearColor;"
			"ClearSetDepth=ClearDepth;"
			"Clear=Color;"
			"Clear=Depth;"
	        "Pass=DrawNormal;"
		#endif

	    //�ŏI����
        "RenderColorTarget0=;"
	    "RenderDepthStencilTarget=;"
	    "Pass=DrawObject;"
    ;
> {
    pass DrawNormal {
        VertexShader = compile vs_3_0 Basic_VS(false, false, false);
        PixelShader  = compile ps_3_0 Normal_PS(false);
    }
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_Mec_VS(false, true, false);
        PixelShader  = compile ps_3_0 BufferShadow_Mec_PS(false, true, false);
    }
}

technique MainTecBS3  < string MMDPass = "object_ss"; bool UseTexture = true; bool UseSphereMap = true; bool UseToon = false; 
    string Script = 
    	#ifdef USE_BEVEL
	        "RenderColorTarget0=NormalTex;"
		    "RenderDepthStencilTarget=DepthBuffer;"
			"ClearSetColor=ClearColor;"
			"ClearSetDepth=ClearDepth;"
			"Clear=Color;"
			"Clear=Depth;"
	        "Pass=DrawNormal;"
		#endif
		
	    //�ŏI����
        "RenderColorTarget0=;"
	    "RenderDepthStencilTarget=;"
	    "Pass=DrawObject;"
    ;
> {
    pass DrawNormal {
        VertexShader = compile vs_3_0 Basic_VS(false, false, false);
        PixelShader  = compile ps_3_0 Normal_PS(true);
    }
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_Mec_VS(true, true, false);
        PixelShader  = compile ps_3_0 BufferShadow_Mec_PS(true, true, false);
    }
}

// �I�u�W�F�N�g�`��p�e�N�j�b�N�iPMD���f���p�j
technique MainTecBS4  < string MMDPass = "object_ss"; bool UseTexture = false; bool UseSphereMap = false; bool UseToon = true; 
    string Script = 
    	#ifdef USE_BEVEL
	        "RenderColorTarget0=NormalTex;"
		    "RenderDepthStencilTarget=DepthBuffer;"
			"ClearSetColor=ClearColor;"
			"ClearSetDepth=ClearDepth;"
			"Clear=Color;"
			"Clear=Depth;"
	        "Pass=DrawNormal;"
		#endif

	    //�ŏI����
        "RenderColorTarget0=;"
	    "RenderDepthStencilTarget=;"
	    "Pass=DrawObject;"
    ;
> {
    pass DrawNormal {
        VertexShader = compile vs_3_0 Basic_VS(false, false, false);
        PixelShader  = compile ps_3_0 Normal_PS(false);
    }
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_Mec_VS(false, false, true);
        PixelShader  = compile ps_3_0 BufferShadow_Mec_PS(false, false, true);
    }
}

technique MainTecBS5  < string MMDPass = "object_ss"; bool UseTexture = true; bool UseSphereMap = false; bool UseToon = true; 
    string Script = 
    	#ifdef USE_BEVEL
	        "RenderColorTarget0=NormalTex;"
		    "RenderDepthStencilTarget=DepthBuffer;"
			"ClearSetColor=ClearColor;"
			"ClearSetDepth=ClearDepth;"
			"Clear=Color;"
			"Clear=Depth;"
	        "Pass=DrawNormal;"
		#endif

	    //�ŏI����
        "RenderColorTarget0=;"
	    "RenderDepthStencilTarget=;"
	    "Pass=DrawObject;"
    ;
> {
    pass DrawNormal {
        VertexShader = compile vs_3_0 Basic_VS(false, false, false);
        PixelShader  = compile ps_3_0 Normal_PS(true);
    }
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_Mec_VS(true, false, true);
        PixelShader  = compile ps_3_0 BufferShadow_Mec_PS(true, false, true);
    }
}

technique MainTecBS6  < string MMDPass = "object_ss"; bool UseTexture = false; bool UseSphereMap = true; bool UseToon = true; 
    string Script = 
    	#ifdef USE_BEVEL
	        "RenderColorTarget0=NormalTex;"
		    "RenderDepthStencilTarget=DepthBuffer;"
			"ClearSetColor=ClearColor;"
			"ClearSetDepth=ClearDepth;"
			"Clear=Color;"
			"Clear=Depth;"
	        "Pass=DrawNormal;"
		#endif

	    //�ŏI����
        "RenderColorTarget0=;"
	    "RenderDepthStencilTarget=;"
	    "Pass=DrawObject;"
    ;
> {
    pass DrawNormal {
        VertexShader = compile vs_3_0 Basic_VS(false, false, false);
        PixelShader  = compile ps_3_0 Normal_PS(false);
    }
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_Mec_VS(false, true, true);
        PixelShader  = compile ps_3_0 BufferShadow_Mec_PS(false, true, true);
    }
}

technique MainTecBS7  < string MMDPass = "object_ss"; bool UseTexture = true; bool UseSphereMap = true; bool UseToon = true; 
    string Script = 
    	#ifdef USE_BEVEL
	        "RenderColorTarget0=NormalTex;"
		    "RenderDepthStencilTarget=DepthBuffer;"
			"ClearSetColor=ClearColor;"
			"ClearSetDepth=ClearDepth;"
			"Clear=Color;"
			"Clear=Depth;"
	        "Pass=DrawNormal;"
		#endif

	    //�ŏI����
        "RenderColorTarget0=;"
	    "RenderDepthStencilTarget=;"
	    "Pass=DrawObject;"
    ;
> {
    pass DrawNormal {
        VertexShader = compile vs_3_0 Basic_VS(false, false, false);
        PixelShader  = compile ps_3_0 Normal_PS(true);
    }
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_Mec_VS(true, true, true);
        PixelShader  = compile ps_3_0 BufferShadow_Mec_PS(true, true, true);
    }
}



///////////////////////////////////////////////////////////////////////////////////////////////