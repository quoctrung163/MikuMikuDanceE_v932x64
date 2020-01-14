//=============================================================================
// depth.fx
// ikBokeh.fx�̂��߂ɁA���`�̐[�x�����o�͂���B
//=============================================================================

//=============================================================================
// MikuMikuMob�Ή� ��������

// &InsertHeader;  ������MikuMikuMob�ݒ�w�b�_�R�[�h���}������܂�

// MikuMikuMob�Ή� �����܂�
//=============================================================================


// �p�����[�^�錾

// �����e�N�X�`���𖳎����郿�l�̏��
const float AlphaThroughThreshold = 0.2;

// �Ȃɂ��Ȃ��`�悵�Ȃ��ꍇ�́A�w�i�܂ł̋���
// �����M��ꍇ�AikBokeh.fx�̓����l���ύX����K�v������B
#define FAR_DEPTH		1000

#define USE_TEXTURE		1

//=============================================================================

//=============================================================================
// depth.fx
// ikBokeh.fx�̂��߂ɁA���`�̐[�x�����o�͂���B
//=============================================================================

//=============================================================================

// ���@�ϊ��s��
float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 WorldMatrix              : WORLD;
float4x4 ViewMatrix               : VIEW;
float4x4 ProjMatrix				  : PROJECTION;
float4x4 LightWorldViewProjMatrix : WORLDVIEWPROJECTION < string Object = "Light"; >;

float4x4 matW	: WORLD;
float4x4 matV	: VIEW;
float4x4 matVP	: VIEWPROJECTION;

float3   LightDirection    : DIRECTION < string Object = "Light"; >;
float3   CameraPosition    : POSITION  < string Object = "Camera"; >;

// �}�e���A���F
float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;
// �ގ����[�t�Ή�
float4	TextureAddValue   : ADDINGTEXTURE;
float4	TextureMulValue   : MULTIPLYINGTEXTURE;

#if USE_TEXTURE > 0
// �I�u�W�F�N�g�̃e�N�X�`��
texture ObjectTexture: MATERIALTEXTURE;
sampler ObjTexSampler = sampler_state {
    texture = <ObjectTexture>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};
#endif

// MMD�{����sampler���㏑�����Ȃ����߂̋L�q�ł��B�폜�s�B
sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);


#if USE_TEXTURE > 0
float4 GetTextureColor(float2 uv)
{
	float4 TexColor = tex2D( ObjTexSampler, uv);
	TexColor.rgb = lerp(1, TexColor * TextureMulValue + TextureAddValue, TextureMulValue.a + TextureAddValue.a).rgb;
	return TexColor;
}
#else
float4 GetTextureColor(float2 uv) { return 1; }
#endif

//=============================================================================

struct BufferShadow_OUTPUT {
	float4 Pos		: POSITION;		// �ˉe�ϊ����W
	float2 Tex		: TEXCOORD1;	// �e�N�X�`��
	float4 VPos		: TEXCOORD2;	// Position
};


//=============================================================================
// ���_�V�F�[�_
BufferShadow_OUTPUT BufferShadow_VS(
	float4 Pos : POSITION, 
	float3 Normal : NORMAL, 
	float2 Tex : TEXCOORD0, 
	int vIndex : _INDEX, 
	uniform bool useTexture)
{
	BufferShadow_OUTPUT Out = (BufferShadow_OUTPUT)0;

	float4 LPos = mul( Pos, matW );
	float4 WPos = MOB_TransformPosition(LPos, vIndex);

	Out.Pos = mul(WPos, matVP);
	Out.VPos = mul(WPos, matV);

	Out.Tex = Tex;

	return Out;
}

float4 BufferShadow_PS(BufferShadow_OUTPUT IN, uniform bool useTexture) : COLOR
{
	float alpha = MaterialDiffuse.a;
	if ( useTexture ) {
		alpha *= GetTextureColor( IN.Tex ).a;
	}

	clip(alpha - AlphaThroughThreshold);

	float distance = length(IN.VPos.xyz);

	return float4(distance / FAR_DEPTH, 0, 0, 1);
}

#define BASICSHADOW_TEC(name, mmdpass, tex) \
	technique name < \
		string MMDPass = mmdpass; bool UseTexture = tex; \
		string Script = MOB_LOOPSCRIPT_OBJECT; \
	> { \
		pass DrawObject { \
			VertexShader = compile vs_3_0 BufferShadow_VS(tex); \
			PixelShader  = compile ps_3_0 BufferShadow_PS(tex); \
		} \
	}

BASICSHADOW_TEC(BTec0, "object", false)
BASICSHADOW_TEC(BTec1, "object", true)

BASICSHADOW_TEC(BSTec0, "object_ss", false)
BASICSHADOW_TEC(BSTec1, "object_ss", true)


technique EdgeTec < string MMDPass = "edge"; > {}
technique ShadowTech < string MMDPass = "shadow";  > {}
technique ZplotTec < string MMDPass = "zplot"; > {}

//=============================================================================

