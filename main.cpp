/////////////////////////////////////////////
//                                         //
//    Copyright (C) 2020-2020 Julian Uy    //
//  https://sites.google.com/site/awertyb  //
//                                         //
//   See details of license at "LICENSE"   //
//                                         //
/////////////////////////////////////////////

#include "ncbind/ncbind.hpp"
#include <string.h>
#include <stdio.h>

#include <windows.h>
#include <ass/ass.h>
#include "ncbind.hpp"

class krass
{
public:
	~krass()
	{
		if (ass_track)
		{
			ass_free_track(ass_track);
			ass_track = nullptr;
		}
		if (ass_renderer)
		{
			ass_renderer_done(ass_renderer);
			ass_renderer = nullptr;
		}
		if (ass_library)
		{
			ass_library_done(ass_library);
			ass_library = nullptr;
		}
		if (ass_image)
		{
			ass_image = nullptr;
		}
	}
	krass(iTJSDispatch2 *obj) : self(obj) {}

	bool load_ass_track(ttstr filename)
	{
		char *data = nullptr;
		ULONG size = 0;
		{
			IStream *in = TVPCreateIStream(filename, TJS_BS_READ);
			if (!in)
			{
				TVPAddLog(TJS_W("krass: could not open ASS file"));
				return false;
			}
			STATSTG stat;
			in->Stat(&stat, STATFLAG_NONAME);
			size = (ULONG)(stat.cbSize.QuadPart);
			data = new char[size];
			HRESULT read_result = in->Read(data, size, &size);
			in->Release();
			if (read_result != S_OK)
			{
				TVPAddLog(TJS_W("krass: could not read ASS file"));
				delete[] data;
				return false;
			}
		}
		if (!initialize_ass_library())
		{
			delete[] data;
			return false;
		}
		if (ass_track)
		{
			ass_free_track(ass_track);
			ass_track = nullptr;
		}
		ass_track = ass_read_memory(ass_library, data, size, nullptr);
		delete[] data;
		if (!ass_track)
		{
			TVPAddLog(TJS_W("krass: could not initialize ASS track"));
			return false;
		}
		return true;
	}

	bool ass_set_frame_size_to_image_size()
	{
		if (!initialize_ass_renderer())
		{
			return false;
		}
		if (!GetLayerSize(self, width, height))
		{
			TVPAddLog(TJS_W("krass: could not get layer size"));
			return false;
		}
		ass_set_frame_size(ass_renderer, width, height);
		ass_set_fonts(ass_renderer, nullptr, "sans-serif", ASS_FONTPROVIDER_NONE, nullptr, 1);
		return true;
	}

	tTVInteger render_ass(tjs_int64 now, bool force_blit)
	{
		if (!initialize_ass_renderer())
		{
			return false;
		}
		if (width == 0 || height == 0)
		{
			TVPAddLog(TJS_W("krass: image size is not initialized"));
			return false;
		}
		if (!ass_track)
		{
			TVPAddLog(TJS_W("krass: ass track is not initialized"));
			return false;
		}
		int detect_change = 0;
		ass_image = ass_render_frame(ass_renderer, ass_track, now, &detect_change);
		if (!ass_image)
		{
			TVPAddLog(TJS_W("krass: could not render ass image"));
			return false;
		}
		long pitch;
		tjs_uint8* buffer;
		if (!GetLayerImageForWrite(self, buffer, pitch))
		{
			TVPAddLog(TJS_W("krass: could not get layer buffer"));
			return false;
		}
		if (force_blit || detect_change)
		{
			blend_tree(buffer, pitch, ass_image);
			if (!LayerUpdate(self, 0, 0, width, height))
			{
				TVPAddLog(TJS_W("krass: could not update layer"));
				return false;
			}
		}
		return detect_change;
	}

	tTVInteger step_ass(tjs_int64 now, tjs_int64 movement)
	{
		if (!initialize_ass_renderer())
		{
			return 0;
		}
		if (!ass_track)
		{
			TVPAddLog(TJS_W("krass: ass track is not initialized"));
			return 0;
		}
		return ass_step_sub(ass_track, now, movement);
	}

private:
	iTJSDispatch2 *self;
	ASS_Library *ass_library = nullptr;
	ASS_Track *ass_track = nullptr;
	ASS_Renderer *ass_renderer = nullptr;
	ASS_Image *ass_image = nullptr;
	size_t width = 0, height = 0;

	bool initialize_ass_library()
	{
		if (!ass_library)
		{
			ass_library = ass_library_init();
			if (!ass_library)
			{
				TVPAddLog(TJS_W("krass: could not initialize libass"));
				return false;
			}
			ass_set_message_cb(ass_library, msg_callback, nullptr);
			ass_set_extract_fonts(ass_library, 1);
		}
		return true;
	}

	bool initialize_ass_renderer()
	{
		if (!initialize_ass_library())
		{
			return false;
		}
		if (!ass_renderer)
		{
			ass_renderer = ass_renderer_init(ass_library);
			if (!ass_renderer)
			{
				TVPAddLog(TJS_W("krass: could not initialize ASS renderer"));
				return false;
			}
		}
		return true;
	}

#define _r(c) ((c)>>24)
#define _g(c) (((c)>>16)&0xFF)
#define _b(c) (((c)>>8)&0xFF)
#define _a(c) ((c)&0xFF)

	void blend_single(tjs_uint8* buffer, long pitch, ASS_Image *img)
	{
		tjs_uint8 opacity = 255 - _a(img->color);
		tjs_uint8 r = _r(img->color);
		tjs_uint8 g = _g(img->color);
		tjs_uint8 b = _b(img->color);

		tjs_uint8 *src;
		tjs_uint8 *dst;

		src = img->bitmap;
		dst = buffer + img->dst_y * pitch + img->dst_x * 4;
		for (tjs_int y = 0; y < img->h; y += 1)
		{
			for (tjs_int x = 0; x < img->w; x += 1)
			{
				tjs_uint32 k = ((tjs_uint32) src[x]) * opacity / 255;
				dst[x * 4 + 0] = (k * b + (255 - k) * dst[x * 4 + 0]) / 255;
				dst[x * 4 + 1] = (k * g + (255 - k) * dst[x * 4 + 1]) / 255;
				dst[x * 4 + 2] = (k * r + (255 - k) * dst[x * 4 + 2]) / 255;
				dst[x * 4 + 3] = (k * opacity + (255 - k) * dst[x * 4 + 3]) / 255;
			}
			src += img->stride;
			dst += pitch;
		}
	}

	void blend_tree(tjs_uint8* buffer, long pitch, ASS_Image *img)
	{
		int cnt = 0;
		while (img)
		{
			blend_single(buffer, pitch, img);
			cnt += 1;
			img = img->next;
		}
	}

	static void msg_callback(int level, const char *fmt, va_list va, void *data)
	{
		if (level > 6)
		{
			return;
		}
		int len = vsnprintf(nullptr, 0, fmt, va);
		char *buf = new char[len + 1];
		vsnprintf(buf, len + 1, fmt, va);
		TVPAddLog(ttstr("krass/libass: ") + ttstr(buf));
		delete[] buf;
	}

	static iTJSDispatch2 *LayerClass;
	static bool GetLayerSize(iTJSDispatch2 *lay, size_t &w, size_t &h)
	{
		static ttstr hasImage   (TJS_W("hasImage"));
		static ttstr imageWidth (TJS_W("imageWidth"));
		static ttstr imageHeight(TJS_W("imageHeight"));

		tTVInteger lw, lh;
		if (!LayerPropGet(lay, hasImage) ||
			(lw = LayerPropGet(lay, imageWidth )) <= 0 ||
			(lh = LayerPropGet(lay, imageHeight)) <= 0) return false;
		w = (size_t)lw;
		h = (size_t)lh;
		return true;
	}
	static bool GetLayerImage(iTJSDispatch2 *lay, const tjs_uint8* &ptr, long &pitch)
	{
		static ttstr mainImageBufferPitch(TJS_W("mainImageBufferPitch"));
		static ttstr mainImageBuffer(TJS_W("mainImageBuffer"));

		tTVInteger lpitch, lptr;
		if ((lpitch = LayerPropGet(lay, mainImageBufferPitch)) == 0 ||
			(lptr   = LayerPropGet(lay, mainImageBuffer)) == 0) return false;
		pitch = (long)lpitch;
		ptr = reinterpret_cast<const tjs_uint8*>(lptr);
		return true;
	}
	static bool GetLayerImageForWrite(iTJSDispatch2 *lay, tjs_uint8* &ptr, long &pitch)
	{
		static ttstr mainImageBufferPitch(TJS_W("mainImageBufferPitch"));
		static ttstr mainImageBufferForWrite(TJS_W("mainImageBufferForWrite"));

		tTVInteger lpitch, lptr;
		if ((lpitch = LayerPropGet(lay, mainImageBufferPitch)) == 0 ||
			(lptr   = LayerPropGet(lay, mainImageBufferForWrite)) == 0) return false;
		pitch = (long)lpitch;
		ptr = reinterpret_cast<tjs_uint8*>(lptr);
		return true;
	}
	static bool LayerUpdate(iTJSDispatch2 *lay, tjs_int64 left = 0, tjs_int64 top = 0, tjs_int64 width = 0, tjs_int64 height = 0)
	{
		if (!LayerClass) {
			tTJSVariant var;
			TVPExecuteExpression(TJS_W("Layer"), &var);
			LayerClass = var.AsObjectNoAddRef();
		}
		tTJSVariant val[4];
		tTJSVariant *pval[4] = { val, val + 1, val + 2, val + 3 };
		val[0] = left;
		val[1] = top;
		val[2] = width;
		val[3] = height;
		static tjs_uint32 update_hint = 0;
		return (TJS_SUCCEEDED(LayerClass->FuncCall(0, TJS_W("update"), &update_hint, NULL, 4, pval, lay)));
	}
	static tTVInteger LayerPropGet(iTJSDispatch2 *lay, ttstr &prop, tTVInteger defval = 0)
	{
		if (!LayerClass) {
			tTJSVariant var;
			TVPExecuteExpression(TJS_W("Layer"), &var);
			LayerClass = var.AsObjectNoAddRef();
		}
		tTJSVariant val;
		return (TJS_FAILED(LayerClass->PropGet(0, prop.c_str(), prop.GetHint(), &val, lay))) ? defval : val.AsInteger();
	}
};
iTJSDispatch2* krass::LayerClass = 0;


NCB_GET_INSTANCE_HOOK(krass)
{
	NCB_GET_INSTANCE_HOOK_CLASS()
	{
	}
	~NCB_GET_INSTANCE_HOOK_CLASS()
	{
	}
	NCB_INSTANCE_GETTER(objthis)
	{
		ClassT* obj = GetNativeInstance(objthis);
		if (!obj) SetNativeInstance(objthis, (obj = new ClassT(objthis)));
		return obj;
	}
};
NCB_ATTACH_CLASS_WITH_HOOK(krass, Layer)
{
	Method(TJS_W("load_ass_track"), &Class::load_ass_track);
	Method(TJS_W("ass_set_frame_size_to_image_size"), &Class::ass_set_frame_size_to_image_size);
	Method(TJS_W("render_ass"), &Class::render_ass);
	Method(TJS_W("step_ass"), &Class::step_ass);
}

