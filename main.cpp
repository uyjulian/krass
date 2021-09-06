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
		if (self)
		{
			self->Release();
		}
	}
	krass(iTJSDispatch2 *obj)
	{
		self = obj;
	}

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
		if (!LayerClear(self, 0, 0, width, height))
		{
			TVPAddLog(TJS_W("krass: could not clear layer"));
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
		if (detect_change == 1)
		{
			tTJSVariant self_variant(self, self);
			update_tree(self_variant, ass_image);
		}
		else if (detect_change == 2)
		{
			tTJSVariant self_variant(self, self);
			create_tree(self_variant, ass_image);
		}
		return detect_change;
	}

	tTVInteger step_ass(tjs_int64 now, tjs_int64 movement)
	{
		if (!initialize_ass_library())
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

	bool create_single(tTJSVariant parent, ASS_Image *img, tTJSVariant layer_obj)
	{
		long layer_pitch;
		tjs_uint8* layer_buffer;
		{
			if (layer_obj.Type() != tvtObject)
			{
				tTJSVariant window_variant;
				static ttstr window(TJS_W("window"));
				parent.AsObjectNoAddRef()->PropGet(0, window.c_str(), window.GetHint(), &window_variant, parent);
				tTJSVariant *vars[] = {&window_variant, &parent};

				iTJSDispatch2 *layer_obj_dispatch;

				if (TJS_SUCCEEDED(GetLayerClass()->CreateNew(0, NULL, NULL, &layer_obj_dispatch, 2, vars, NULL)))
				{
					layer_obj = tTJSVariant(layer_obj_dispatch, layer_obj_dispatch);
					layer_obj_dispatch->Release();
				}
				else
				{
					return false;
				}
			}

			if (!LayerSetImageSize(layer_obj, img->w, img->h))
			{
				return false;
			}
			if (!LayerSetImagePos(layer_obj, 0, 0))
			{
				return false;
			}
			if (!LayerSetPos(layer_obj, img->dst_x, img->dst_y, img->w, img->h))
			{
				return false;
			}
			if (!LayerClear(layer_obj, 0, 0, img->w, img->h))
			{
				return false;
			}
			if (!GetLayerImageForWrite(layer_obj, layer_buffer, layer_pitch))
			{
				return false;
			}
			static ttstr visible(TJS_W("visible"));
			if (!LayerPropSet(layer_obj, visible, 1))
			{
				return false;
			}
		}

		tjs_uint8 a = 255 - _a(img->color);
		tjs_uint8 r = _r(img->color);
		tjs_uint8 g = _g(img->color);
		tjs_uint8 b = _b(img->color);

		tjs_uint8 *src;
		tjs_uint8 *dst;

		src = img->bitmap;
		dst = layer_buffer;
		for (tjs_int y = 0; y < img->h; y += 1)
		{
			for (tjs_int x = 0; x < img->w; x += 1)
			{
				dst[x * 4 + 0] = (src[x] * b) / 255;
				dst[x * 4 + 1] = (src[x] * g) / 255;
				dst[x * 4 + 2] = (src[x] * r) / 255;
				dst[x * 4 + 3] = (src[x] * a) / 255;
			}
			src += img->stride;
			dst += layer_pitch;
		}

		if (!LayerUpdate(layer_obj, 0, 0, img->w, img->h))
		{
			return false;
		}

		return true;
	}

	void create_tree(tTJSVariant parent, ASS_Image *img)
	{
		tTJSVariant * children_array = GetLayerChildren(parent);
		if (children_array != nullptr)
		{
			for (int i = 0; children_array[i].Type() == tvtObject; i += 1)
			{
				if (img)
				{
					create_single(parent, img, children_array[i]);
					img = img->next;
				}
				else
				{
					static ttstr visible(TJS_W("visible"));
					LayerPropSet(children_array[i], visible, 0);
				}
			}
			delete[] children_array;
		}
		while (img)
		{
			tTJSVariant empty;
			create_single(parent, img, empty);
			img = img->next;
		}
	}

	void update_tree(tTJSVariant parent, ASS_Image *img)
	{
		tTJSVariant * children_array = GetLayerChildren(parent);
		if (children_array != nullptr)
		{
			for (int i = 0; children_array[i].Type() == tvtObject; i += 1)
			{
				if (img)
				{
					if (!LayerSetPos(children_array[i], img->dst_x, img->dst_y, img->w, img->h))
					{
						break;
					}
					img = img->next;
				}
			}
			delete[] children_array;
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
	static iTJSDispatch2 * GetLayerClass(void)
	{
		if (!LayerClass) {
			tTJSVariant var;
			TVPExecuteExpression(TJS_W("Layer"), &var);
			LayerClass = var.AsObjectNoAddRef();
		}
		return LayerClass;
	}
	static tTJSVariant * GetLayerChildren(iTJSDispatch2 *lay)
	{
		iTJSDispatch2 * layer_class = GetLayerClass();
		tTJSVariant layer_children_variant;
		static ttstr children(TJS_W("children"));
		if (TJS_FAILED(layer_class->PropGet(0, children.c_str(), children.GetHint(), &layer_children_variant, lay)))
		{
			return nullptr;
		}
		static ttstr count(TJS_W("count"));
		tTJSVariant arr_count_variant;
		if (TJS_FAILED(layer_children_variant.AsObjectNoAddRef()->PropGet(0, count.c_str(), count.GetHint(), &arr_count_variant, layer_children_variant)))
		{
			return nullptr;
		}
		if (arr_count_variant.AsInteger() == 0)
		{
			return nullptr;
		}
		tTJSVariant * children_array = new tTJSVariant[arr_count_variant.AsInteger() + 1];
		for (size_t i = 0; i < arr_count_variant.AsInteger(); i += 1)
		{
			tTJSVariant child_variant;
			if (TJS_FAILED(layer_children_variant.AsObjectNoAddRef()->PropGetByNum(0, i, &child_variant, layer_children_variant)))
			{
				delete[] children_array;
				return nullptr;
			}
			children_array[i] = child_variant;
		}
		return children_array;
	}
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
	static bool LayerClear(iTJSDispatch2 *lay, tjs_int64 left = 0, tjs_int64 top = 0, tjs_int64 width = 0, tjs_int64 height = 0)
	{
		static ttstr fillRect(TJS_W("fillRect"));
		tTJSVariant val[5];
		tTJSVariant *pval[5] = { val, val + 1, val + 2, val + 3, val + 4 };
		val[0] = left;
		val[1] = top;
		val[2] = width;
		val[3] = height;
		val[4] = 0;
		return (TJS_SUCCEEDED(GetLayerClass()->FuncCall(0, fillRect.c_str(), fillRect.GetHint(), NULL, 5, pval, lay)));
	}
	static bool LayerSetPos(iTJSDispatch2 *lay, tjs_int64 left = 0, tjs_int64 top = 0, tjs_int64 width = 0, tjs_int64 height = 0)
	{
		static ttstr setPos(TJS_W("setPos"));
		tTJSVariant val[4];
		tTJSVariant *pval[4] = { val, val + 1, val + 2, val + 3};
		val[0] = left;
		val[1] = top;
		val[2] = width;
		val[3] = height;
		return (TJS_SUCCEEDED(GetLayerClass()->FuncCall(0, setPos.c_str(), setPos.GetHint(), NULL, 4, pval, lay)));
	}
	static bool LayerSetImageSize(iTJSDispatch2 *lay, tjs_int64 width = 0, tjs_int64 height = 0)
	{
		static ttstr setImageSize(TJS_W("setImageSize"));
		tTJSVariant val[2];
		tTJSVariant *pval[2] = { val, val + 1};
		val[0] = width;
		val[1] = height;
		return (TJS_SUCCEEDED(GetLayerClass()->FuncCall(0, setImageSize.c_str(), setImageSize.GetHint(), NULL, 2, pval, lay)));
	}
	static bool LayerSetImagePos(iTJSDispatch2 *lay, tjs_int64 left = 0, tjs_int64 top = 0)
	{
		static ttstr setImagePos(TJS_W("setImagePos"));
		tTJSVariant val[2];
		tTJSVariant *pval[2] = { val, val + 1};
		val[0] = left;
		val[1] = top;
		return (TJS_SUCCEEDED(GetLayerClass()->FuncCall(0, setImagePos.c_str(), setImagePos.GetHint(), NULL, 2, pval, lay)));
	}
	static bool LayerSetSizeToImageSize(iTJSDispatch2 *lay)
	{
		static ttstr setSizeToImageSize(TJS_W("setSizeToImageSize"));
		return (TJS_SUCCEEDED(GetLayerClass()->FuncCall(0, setSizeToImageSize.c_str(), setSizeToImageSize.GetHint(), NULL, 0, NULL, lay)));
	}
	static bool LayerUpdate(iTJSDispatch2 *lay, tjs_int64 left = 0, tjs_int64 top = 0, tjs_int64 width = 0, tjs_int64 height = 0)
	{
		static ttstr update(TJS_W("update"));
		tTJSVariant val[4];
		tTJSVariant *pval[4] = { val, val + 1, val + 2, val + 3 };
		val[0] = left;
		val[1] = top;
		val[2] = width;
		val[3] = height;
		return (TJS_SUCCEEDED(GetLayerClass()->FuncCall(0, update.c_str(), update.GetHint(), NULL, 4, pval, lay)));
	}
	static tTVInteger LayerPropGet(iTJSDispatch2 *lay, ttstr &prop, tTVInteger defval = 0)
	{
		tTJSVariant val;
		return (TJS_FAILED(GetLayerClass()->PropGet(0, prop.c_str(), prop.GetHint(), &val, lay))) ? defval : val.AsInteger();
	}
	static bool LayerPropSet(iTJSDispatch2 *lay, ttstr &prop, tTJSVariant val)
	{
		return (TJS_SUCCEEDED(GetLayerClass()->PropSet(TJS_MEMBERENSURE, prop.c_str(), prop.GetHint(), &val, lay)));
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

