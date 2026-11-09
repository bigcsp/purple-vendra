-- Purple Vendra — rename "Fashion & Adé" to "Fashion & Adire" (6 Nov 2026)

update categories
set name = 'Fashion & Adire',
    slug = 'fashion-adire'
where slug = 'fashion-ade';
