import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const StockManagementApp());

const navy = Color(0xFF14213D);
const blue = Color(0xFF3563E9);
const canvas = Color(0xFFF4F7FC);
const green = Color(0xFF159A75);
const orange = Color(0xFFF59E0B);
const red = Color(0xFFE34D59);

class StockManagementApp extends StatelessWidget {
  const StockManagementApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas, foregroundColor: navy, elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
      home: const StockHome(),
    );
  }
}

String money(num n) => NumberFormat.currency(symbol: 'RWF ', decimalDigits: 0).format(n);
String dateText(DateTime d) => DateFormat('dd MMM yyyy, HH:mm').format(d);

class Product {
  String id, name, sku, category;
  int quantity, minimum;
  double price;
  Product({required this.id, required this.name, required this.sku,
    required this.category, required this.quantity, required this.minimum,
    required this.price});
  Map<String, dynamic> toJson() => {'id':id,'name':name,'sku':sku,'category':category,
    'quantity':quantity,'minimum':minimum,'price':price};
  factory Product.fromJson(Map<String,dynamic> j) => Product(
    id:j['id'], name:j['name'], sku:j['sku'], category:j['category'] ?? 'General',
    quantity:(j['quantity'] as num).toInt(), minimum:(j['minimum'] as num).toInt(),
    price:(j['price'] as num).toDouble());
}

class Movement {
  String id, productId, productName, type, note;
  int quantity;
  DateTime date;
  Movement({required this.id, required this.productId, required this.productName,
    required this.type, required this.quantity, required this.date, this.note = ''});
  Map<String,dynamic> toJson() => {'id':id,'productId':productId,'productName':productName,
    'type':type,'quantity':quantity,'date':date.toIso8601String(),'note':note};
  factory Movement.fromJson(Map<String,dynamic> j) => Movement(
    id:j['id'], productId:j['productId'], productName:j['productName'], type:j['type'],
    quantity:(j['quantity'] as num).toInt(), date:DateTime.parse(j['date']), note:j['note'] ?? '');
}

class StockHome extends StatefulWidget {
  const StockHome({super.key});
  @override
  State<StockHome> createState() => _StockHomeState();
}

class _StockHomeState extends State<StockHome> {
  int page = 0;
  bool loading = true;
  final List<Product> products = [];
  final List<Movement> movements = [];
  final searchController = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final ps = p.getString('products_v1');
    final ms = p.getString('movements_v1');
    if (ps != null) products.addAll((jsonDecode(ps) as List).map((e)=>Product.fromJson(e)));
    if (ms != null) movements.addAll((jsonDecode(ms) as List).map((e)=>Movement.fromJson(e)));
    if (products.isEmpty && ps == null) {
      products.addAll([
        Product(id:'p1',name:'Wireless Mouse',sku:'ACC-001',category:'Accessories',quantity:32,minimum:8,price:8500),
        Product(id:'p2',name:'USB-C Cable',sku:'ACC-002',category:'Accessories',quantity:7,minimum:10,price:4500),
        Product(id:'p3',name:'Notebook 15-inch',sku:'EL-003',category:'Electronics',quantity:14,minimum:5,price:685000),
        Product(id:'p4',name:'Office Chair',sku:'FUR-004',category:'Furniture',quantity:4,minimum:5,price:125000),
      ]);
      await _save();
    }
    if (mounted) setState(()=>loading=false);
  }
  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('products_v1', jsonEncode(products.map((e)=>e.toJson()).toList()));
    await p.setString('movements_v1', jsonEncode(movements.map((e)=>e.toJson()).toList()));
  }
  int get totalUnits => products.fold(0,(s,p)=>s+p.quantity);
  double get totalValue => products.fold(0,(s,p)=>s+p.quantity*p.price);
  int get lowStock => products.where((p)=>p.quantity<=p.minimum).length;

  void _toast(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(s), behavior: SnackBarBehavior.floating));

  Future<void> _productDialog({Product? product}) async {
    final name = TextEditingController(text:product?.name ?? '');
    final sku = TextEditingController(text:product?.sku ?? '');
    final category = TextEditingController(text:product?.category ?? 'General');
    final quantity = TextEditingController(text:product?.quantity.toString() ?? '0');
    final minimum = TextEditingController(text:product?.minimum.toString() ?? '5');
    final price = TextEditingController(text:product?.price.toStringAsFixed(0) ?? '');
    final form = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product == null ? 'Add product' : 'Edit product'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 420,
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Product name'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter a product name'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: sku,
                    decoration: const InputDecoration(labelText: 'SKU / product code'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter a SKU'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: quantity,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Quantity'),
                          validator: _nonNegativeInt,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: minimum,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Low-stock level'),
                          validator: _nonNegativeInt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Unit price (RWF)'),
                    validator: _nonNegativeNum,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, form.currentState!.validate()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if(result!=true) return;
    final q=int.parse(quantity.text), min=int.parse(minimum.text);
    if(product==null) {
      if(products.any((p)=>p.sku.toLowerCase()==sku.text.trim().toLowerCase())) {
        _toast('That SKU already exists. Use a unique product code.'); return;
      }
      final p=Product(id:DateTime.now().microsecondsSinceEpoch.toString(),name:name.text.trim(),
        sku:sku.text.trim(),category:category.text.trim().isEmpty?'General':category.text.trim(),
        quantity:q,minimum:min,price:double.parse(price.text));
      products.insert(0,p);
      if(q>0) movements.insert(0,Movement(id:DateTime.now().microsecondsSinceEpoch.toString(),
        productId:p.id,productName:p.name,type:'IN',quantity:q,date:DateTime.now(),note:'Opening stock'));
    } else {
      if(products.any((p)=>p.id!=product.id && p.sku.toLowerCase()==sku.text.trim().toLowerCase())) {
        _toast('That SKU already exists. Use a unique product code.'); return;
      }
      product.name=name.text.trim(); product.sku=sku.text.trim();
      product.category=category.text.trim().isEmpty?'General':category.text.trim();
      product.quantity=q; product.minimum=min; product.price=double.parse(price.text);
    }
    await _save(); if(mounted) setState((){}); _toast('Product saved successfully.');
  }
  String? _nonNegativeInt(String? v) {
    final n=int.tryParse(v??''); if(n==null||n<0) return 'Enter a whole number ≥ 0'; return null;
  }
  String? _nonNegativeNum(String? v) {
    final n=double.tryParse(v??''); if(n==null||n<0) return 'Enter a valid price ≥ 0'; return null;
  }

  Future<void> _deleteProduct(Product p) async {
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Delete product?'),
      content:Text('Delete "${p.name}"? Its existing transaction history will remain.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
        FilledButton(style:FilledButton.styleFrom(backgroundColor:red),
          onPressed:()=>Navigator.pop(ctx,true),child:const Text('Delete'))]));
    if(ok==true){products.removeWhere((x)=>x.id==p.id);await _save();if(mounted)setState((){});_toast('Product deleted.');}
  }

  Future<void> _movementDialog(String type) async {
    if(products.isEmpty){_toast('Add a product before recording stock.');return;}
    Product selected=products.first;
    final qty=TextEditingController(text:'1'), note=TextEditingController();
    final form=GlobalKey<FormState>();
    final result=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:Text(type=='IN'?'Record stock-in':'Record stock-out'),
      content:SizedBox(width:420,child:Form(key:form,child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<Product>(value:selected,isExpanded:true,decoration:const InputDecoration(labelText:'Product'),
          items:products.map((p)=>DropdownMenuItem(value:p,child:Text('${p.name} (${p.quantity} available)',overflow:TextOverflow.ellipsis))).toList(),
          onChanged:(p){if(p!=null)refresh(()=>selected=p);}),
        const SizedBox(height:12),
        TextFormField(controller:qty,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Quantity'),
          validator:(v){final n=int.tryParse(v??'');if(n==null||n<=0)return 'Enter a quantity greater than zero';
            if(type=='OUT'&&n>selected.quantity)return 'Only ${selected.quantity} units are available';return null;}),
        const SizedBox(height:12),
        TextFormField(controller:note,decoration:const InputDecoration(labelText:'Note (optional)')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,form.currentState!.validate()),child:const Text('Save transaction'))],
    )));
    if(result!=true)return;
    final n=int.parse(qty.text);
    if(type=='OUT'&&n>selected.quantity){_toast('Not enough stock available.');return;}
    selected.quantity += type=='IN'?n:-n;
    movements.insert(0,Movement(id:DateTime.now().microsecondsSinceEpoch.toString(),productId:selected.id,
      productName:selected.name,type:type,quantity:n,date:DateTime.now(),note:note.text.trim()));
    await _save();if(mounted)setState((){});_toast(type=='IN'?'Stock received successfully.':'Stock issued successfully.');
  }

  @override
  Widget build(BuildContext context) {
    final titles=['Dashboard','Products','Stock movements','Reports'];
    return Scaffold(
      appBar:AppBar(title:Row(children:[
        Container(width:38,height:38,decoration:BoxDecoration(color:blue,borderRadius:BorderRadius.circular(12)),
          child:const Icon(Icons.inventory_2_rounded,color:Colors.white)),
        const SizedBox(width:10),
        Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('StockFlow',style:TextStyle(fontWeight:FontWeight.w800,fontSize:20)),
          Text(titles[page],style:TextStyle(fontSize:12,color:Colors.grey.shade600)),
        ]),
      ]), actions:[IconButton(tooltip:'Refresh data',onPressed:()=>setState((){}),icon:const Icon(Icons.refresh_rounded)),const SizedBox(width:8)]),
      body:loading?const Center(child:CircularProgressIndicator()):SafeArea(child:IndexedStack(index:page,children:[
        _dashboard(),_productsPage(),_movementsPage(),_reportsPage(),
      ])),
      floatingActionButton:page==1?FloatingActionButton.extended(onPressed:()=>_productDialog(),
        backgroundColor:blue,foregroundColor:Colors.white,icon:const Icon(Icons.add),label:const Text('Add product')):null,
      bottomNavigationBar:NavigationBar(selectedIndex:page,onDestinationSelected:(v)=>setState(()=>page=v),
        destinations:const [
          NavigationDestination(icon:Icon(Icons.space_dashboard_outlined),selectedIcon:Icon(Icons.space_dashboard),label:'Home'),
          NavigationDestination(icon:Icon(Icons.inventory_2_outlined),selectedIcon:Icon(Icons.inventory_2),label:'Products'),
          NavigationDestination(icon:Icon(Icons.swap_vert_circle_outlined),selectedIcon:Icon(Icons.swap_vert_circle),label:'Movements'),
          NavigationDestination(icon:Icon(Icons.bar_chart_outlined),selectedIcon:Icon(Icons.bar_chart),label:'Reports'),
        ]),
    );
  }

  Widget _dashboard()=>ListView(padding:const EdgeInsets.all(18),children:[
    Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(
      gradient:const LinearGradient(colors:[navy,Color(0xFF263F72)],begin:Alignment.topLeft,end:Alignment.bottomRight),
      borderRadius:BorderRadius.circular(24)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('INVENTORY OVERVIEW',style:TextStyle(color:Color(0xFFB8C8E8),fontSize:12,letterSpacing:1.5,fontWeight:FontWeight.bold)),
        const SizedBox(height:10),
        const Text('Your stock, at a glance.',style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.bold)),
        const SizedBox(height:6),
        Text('${DateFormat('EEEE, d MMMM yyyy').format(DateTime.now())}',style:const TextStyle(color:Color(0xFFD6E0F3))),
        const SizedBox(height:20),
        Wrap(spacing:10,runSpacing:10,children:[
          FilledButton.icon(onPressed:()=>_movementDialog('IN'),icon:const Icon(Icons.add_box_outlined),label:const Text('Stock in'),
            style:FilledButton.styleFrom(backgroundColor:blue,foregroundColor:Colors.white)),
          OutlinedButton.icon(onPressed:()=>_movementDialog('OUT'),icon:const Icon(Icons.outbox_outlined),label:const Text('Stock out'),
            style:OutlinedButton.styleFrom(foregroundColor:Colors.white,side:const BorderSide(color:Color(0xFF7186AD)))),
        ]),
      ])),
    const SizedBox(height:18),
    GridView.count(crossAxisCount:MediaQuery.of(context).size.width>700?4:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
      crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.48,children:[
        _stat('Products',products.length.toString(),Icons.inventory_2_outlined,blue),
        _stat('Units in stock',NumberFormat('#,##0').format(totalUnits),Icons.widgets_outlined,green),
        _stat('Stock value',money(totalValue),Icons.account_balance_wallet_outlined,Color(0xFF8658D8)),
        _stat('Low stock',lowStock.toString(),Icons.warning_amber_rounded,lowStock>0?orange:green),
      ]),
    const SizedBox(height:24),
    _sectionTitle('Low-stock alerts', 'See products that need attention'),
    const SizedBox(height:10),
    if(products.where((p)=>p.quantity<=p.minimum).isEmpty)
      _empty('All good! No low-stock products.','Your inventory is above its alert levels.',Icons.check_circle_outline)
    else ...products.where((p)=>p.quantity<=p.minimum).take(5).map(_lowStockTile),
    const SizedBox(height:24),
    _sectionTitle('Recent movements','Latest stock changes'),
    const SizedBox(height:10),
    if(movements.isEmpty)_empty('No movements yet','Stock transactions will appear here.',Icons.swap_vert)
    else ...movements.take(5).map(_movementTile),
  ]);

  Widget _stat(String label,String value,IconData icon,Color color)=>Container(
    padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),
      border:Border.all(color:const Color(0xFFE8EDF5))),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:color.withOpacity(.11),borderRadius:BorderRadius.circular(11)),
        child:Icon(icon,color:color,size:20)),
      const SizedBox(height:8),
      FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Text(value,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:19,color:navy))),
      Text(label,style:TextStyle(color:Colors.grey.shade600,fontSize:12),maxLines:1,overflow:TextOverflow.ellipsis),
    ]));

  Widget _sectionTitle(String title,String subtitle)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:17,color:navy)),
    const SizedBox(height:3),Text(subtitle,style:TextStyle(color:Colors.grey.shade600,fontSize:12)),
  ]);
  Widget _lowStockTile(Product p)=>Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15)),
    child:Row(children:[
      Container(width:42,height:42,decoration:BoxDecoration(color:orange.withOpacity(.12),borderRadius:BorderRadius.circular(12)),
        child:const Icon(Icons.inventory_2_outlined,color:orange)),
      const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(p.name,style:const TextStyle(fontWeight:FontWeight.w700)),Text(p.sku,style:TextStyle(color:Colors.grey.shade600,fontSize:12)),
      ])),
      Text('${p.quantity} left',style:const TextStyle(color:red,fontWeight:FontWeight.bold)),
    ]));

  Widget _productsPage(){
    final query=searchController.text.toLowerCase();
    final list=products.where((p)=>p.name.toLowerCase().contains(query)||p.sku.toLowerCase().contains(query)||p.category.toLowerCase().contains(query)).toList();
    return ListView(padding:const EdgeInsets.all(16),children:[
      Text('Manage your inventory',style:TextStyle(color:Colors.grey.shade700)),
      const SizedBox(height:14),
      TextField(controller:searchController,onChanged:(_)=>setState((){}),
        decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search name, SKU or category')),
      const SizedBox(height:14),
      Row(children:[Text('${list.length} products',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),const Spacer(),
        Text('Tap a row to edit',style:TextStyle(color:Colors.grey.shade600,fontSize:12))]),
      const SizedBox(height:8),
      if(list.isEmpty)_empty('No products found','Try another search or add a product.',Icons.search_off)
      else ...list.map(_productCard),
    ]);
  }

  Widget _productCard(Product p) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE8EDF5)),
    ),
    margin: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _productDialog(product: p),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: blue.withOpacity(.09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${p.sku} • ${p.category}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    money(p.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: navy,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${p.quantity} units',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: p.quantity <= p.minimum ? red : green,
                  ),
                ),
                Text(
                  'Min ${p.minimum}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (v) {
                    if (v == 'edit') _productDialog(product: p);
                    if (v == 'delete') _deleteProduct(p);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  child: const Icon(Icons.more_horiz),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _movementsPage()=>ListView(padding:const EdgeInsets.all(16),children:[
    _sectionTitle('Stock movements','Every incoming and outgoing transaction'),
    const SizedBox(height:14),
    Row(children:[
      Expanded(child:FilledButton.icon(onPressed:()=>_movementDialog('IN'),icon:const Icon(Icons.add),label:const Text('Stock in'))),
      const SizedBox(width:10),
      Expanded(child:OutlinedButton.icon(onPressed:()=>_movementDialog('OUT'),icon:const Icon(Icons.remove),label:const Text('Stock out'))),
    ]),
    const SizedBox(height:18),
    if(movements.isEmpty)_empty('No transactions yet','Record stock-in or stock-out to begin.',Icons.swap_vert)
    else ...movements.map(_movementTile),
  ]);

  Widget _movementTile(Movement m)=>Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:const Color(0xFFE8EDF5))),
    child:Row(children:[
      Container(width:42,height:42,decoration:BoxDecoration(color:(m.type=='IN'?green:red).withOpacity(.11),borderRadius:BorderRadius.circular(12)),
        child:Icon(m.type=='IN'?Icons.south_west:Icons.north_east,color:m.type=='IN'?green:red)),
      const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(m.productName,style:const TextStyle(fontWeight:FontWeight.bold)),
        Text('${m.type=='IN'?'Stock received':'Stock issued'} • ${dateText(m.date)}',style:TextStyle(color:Colors.grey.shade600,fontSize:11)),
        if(m.note.isNotEmpty)Text(m.note,style:TextStyle(color:Colors.grey.shade600,fontSize:11)),
      ])),
      Text('${m.type=='IN'?'+':'−'}${m.quantity}',style:TextStyle(fontWeight:FontWeight.w800,color:m.type=='IN'?green:red,fontSize:17)),
    ]));

  Widget _reportsPage()=>_ReportsView(products:products,movements:movements,totalUnits:totalUnits,totalValue:totalValue,lowStock:lowStock);

  Widget _empty(String title,String subtitle,IconData icon)=>Container(
    padding:const EdgeInsets.all(26),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),
    child:Column(children:[Icon(icon,size:34,color:blue),const SizedBox(height:10),
      Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:4),
      Text(subtitle,textAlign:TextAlign.center,style:TextStyle(color:Colors.grey.shade600,fontSize:12))]));
}

class _ReportsView extends StatefulWidget {
  final List<Product> products;
  final List<Movement> movements;
  final int totalUnits, lowStock;
  final double totalValue;
  const _ReportsView({required this.products,required this.movements,required this.totalUnits,
    required this.totalValue,required this.lowStock});
  @override
  State<_ReportsView> createState()=>_ReportsViewState();
}
class _ReportsViewState extends State<_ReportsView>{
  String period='Today';
  DateTime _start(DateTime now){
    switch(period){
      case 'Today':return DateTime(now.year,now.month,now.day);
      case 'This week':return DateTime(now.year,now.month,now.day).subtract(Duration(days:now.weekday-1));
      case 'This month':return DateTime(now.year,now.month);
      case 'This year':return DateTime(now.year);
      default:return DateTime(2000);
    }
  }
  @override
  Widget build(BuildContext context){
    final now=DateTime.now(), start=_start(now);
    final list=widget.movements.where((m)=>!m.date.isBefore(start)&&!m.date.isAfter(now)).toList();
    final incoming=list.where((m)=>m.type=='IN').fold(0,(s,m)=>s+m.quantity);
    final outgoing=list.where((m)=>m.type=='OUT').fold(0,(s,m)=>s+m.quantity);
    return ListView(padding:const EdgeInsets.all(16),children:[
      const Text('Inventory reports',style:TextStyle(fontWeight:FontWeight.w800,fontSize:22,color:navy)),
      const SizedBox(height:4),Text('Review stock activity for a selected period.',style:TextStyle(color:Colors.grey.shade600)),
      const SizedBox(height:16),
      Wrap(spacing:8,runSpacing:8,children:['Today','This week','This month','This year','All time'].map((p)=>ChoiceChip(
        label:Text(p),selected:period==p,onSelected:(_)=>setState(()=>period=p))).toList()),
      const SizedBox(height:16),
      _reportCard('Stock received',incoming.toString(),Icons.south_west,green),
      _reportCard('Stock issued',outgoing.toString(),Icons.north_east,red),
      _reportCard('Transactions',list.length.toString(),Icons.receipt_long_outlined,blue),
      const SizedBox(height:14),
      Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Current inventory summary',style:TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
          const SizedBox(height:14),
          _summaryLine('Products',widget.products.length.toString()),
          _summaryLine('Units currently in stock',NumberFormat('#,##0').format(widget.totalUnits)),
          _summaryLine('Estimated stock value',money(widget.totalValue)),
          _summaryLine('Products at low-stock level',widget.lowStock.toString()),
        ])),
      const SizedBox(height:18),
      const Text('Transactions in selected period',style:TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
      const SizedBox(height:10),
      if(list.isEmpty)Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),
        child:const Text('No transactions in this period.',textAlign:TextAlign.center))
      else ...list.map((m)=>Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(12),
        decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(13)),
        child:Row(children:[Icon(m.type=='IN'?Icons.south_west:Icons.north_east,color:m.type=='IN'?green:red),
          const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(m.productName,style:const TextStyle(fontWeight:FontWeight.w600)),
            Text(dateText(m.date),style:TextStyle(color:Colors.grey.shade600,fontSize:11)),
          ])),Text('${m.type=='IN'?'+':'−'}${m.quantity}',style:TextStyle(color:m.type=='IN'?green:red,fontWeight:FontWeight.bold))]))),
    ]);
  }
  Widget _reportCard(String title,String value,IconData icon,Color color)=>Container(
    margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(15),
    decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),
    child:Row(children:[Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:color.withOpacity(.1),borderRadius:BorderRadius.circular(12)),
      child:Icon(icon,color:color)),const SizedBox(width:12),Expanded(child:Text(title,style:TextStyle(color:Colors.grey.shade700))),
      Text(value,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:20,color:navy))]));
  Widget _summaryLine(String label,String value)=>Padding(padding:const EdgeInsets.symmetric(vertical:7),
    child:Row(children:[Expanded(child:Text(label,style:TextStyle(color:Colors.grey.shade700))),Text(value,style:const TextStyle(fontWeight:FontWeight.bold,color:navy))]));
}
