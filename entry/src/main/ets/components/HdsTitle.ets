import {
  hdsMaterial,
  HdsNavigationMenuItemOptions,
  HdsNavigationTitleBarOptions,
  ScrollEffectType
} from '@kit.UIDesignKit';


// HdsNavigation/HdsNavDestination 全透明标题栏:FREE 与 MINI(滚动收缩)态均无背景,
// 内容直接从标题栏/状态栏下方穿过。
// avoidLayoutSafeArea 保持开启：窗口顶部安全区由系统接管，标题栏菜单行才能落在状态栏下方
export function hdsTitleBar(mainTitle: ResourceStr,
  menu?: HdsNavigationMenuItemOptions[]): HdsNavigationTitleBarOptions {
  const options: HdsNavigationTitleBarOptions = {
    avoidLayoutSafeArea: true,
    content: { title: { mainTitle } },
    style: {
      scrollEffectOpts: {
        enableScrollEffect: true,
        scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
      },
      systemMaterialEffect:{
        materialType: hdsMaterial.MaterialType.ADAPTIVE,
        materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
      },
      // 透明态下 HDS 默认菜单/返回图标在浅色背景上无对比，两种状态都显式跟随主题文本色
      originalStyle: {
        backgroundStyle: { backgroundColor: Color.Transparent },
        contentStyle: {
          titleStyle: { mainTitleColor: $r('app.color.text_primary') },
          menuStyle: { iconColor: $r('app.color.text_primary') },
          backIconStyle: { iconColor: $r('app.color.text_primary') }
        }
      },
      scrollEffectStyle: {
        backgroundStyle: { backgroundColor: Color.Transparent },
        contentStyle: {
          titleStyle: { mainTitleColor: $r('app.color.text_primary') },
          menuStyle: { iconColor: $r('app.color.text_primary') },
          backIconStyle: { iconColor: $r('app.color.text_primary') }
        }
      }
    }
  };
  if (menu && options.content) {
    options.content.menu = { value: menu };
  }
  return options;
}
